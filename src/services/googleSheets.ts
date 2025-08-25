import { AuthService } from './auth';
import type { ContactInfo, GoogleSheetInfo } from '../types';

// Google Sheets API v4 Base URL
const SHEETS_API_BASE = 'https://sheets.googleapis.com/v4/spreadsheets';

// Google Drive API v3 Base URL (for listing sheets)
const DRIVE_API_BASE = 'https://www.googleapis.com/drive/v3';

export class GoogleSheetsService {
  /**
   * Get authorization headers for API requests
   */
  private static async getAuthHeaders(): Promise<HeadersInit> {
    const accessToken = await AuthService.getAccessToken();
    
    if (!accessToken) {
      throw new Error('User not authenticated. Please sign in first.');
    }

    return {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    };
  }

  /**
   * Get list of Google Sheets accessible to the user via Drive API
   */
  static async listSheets(): Promise<GoogleSheetInfo[]> {
    try {
      const headers = await this.getAuthHeaders();

      // Query Google Drive API for spreadsheet files
      const query = `mimeType='application/vnd.google-apps.spreadsheet' and trashed=false`;
      const url = `${DRIVE_API_BASE}/files?q=${encodeURIComponent(query)}&fields=files(id,name,modifiedTime,webViewLink)&orderBy=modifiedTime desc&pageSize=20`;

      const response = await fetch(url, {
        method: 'GET',
        headers,
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Drive API Error:', response.status, errorText);
        throw new Error(`Failed to fetch Google Sheets: ${response.status}`);
      }

      const data = await response.json();
      
      // Convert Drive API response to our GoogleSheetInfo format
      const sheets: GoogleSheetInfo[] = data.files?.map((file: any) => ({
        id: file.id,
        title: file.name,
        url: file.webViewLink,
        lastModified: file.modifiedTime, // Keep as ISO string for navigation serialization
      })) || [];

      console.log(`Found ${sheets.length} Google Sheets`);
      return sheets;
    } catch (error) {
      console.error('Failed to list sheets:', error);
      throw new Error('Failed to fetch your Google Sheets. Please check your connection and try again.');
    }
  }

  /**
   * Create a new Google Sheet
   */
  static async createSheet(title: string): Promise<GoogleSheetInfo> {
    try {
      const headers = await this.getAuthHeaders();

      // Create spreadsheet request body
      const requestBody = {
        properties: {
          title: title,
        },
        sheets: [{
          properties: {
            title: 'Contacts',
            gridProperties: {
              rowCount: 1000,
              columnCount: 10,
            },
          },
          data: [{
            startRow: 0,
            startColumn: 0,
            rowData: [{
              values: [
                { userEnteredValue: { stringValue: 'Name' } },
                { userEnteredValue: { stringValue: 'Email' } },
                { userEnteredValue: { stringValue: 'Phone' } },
                { userEnteredValue: { stringValue: 'Scanned By' } },
                { userEnteredValue: { stringValue: 'Scanned At' } },
              ],
            }],
          }],
        }],
      };

      const response = await fetch(SHEETS_API_BASE, {
        method: 'POST',
        headers,
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Sheets API Error:', response.status, errorText);
        throw new Error(`Failed to create Google Sheet: ${response.status}`);
      }

      const data = await response.json();

      console.log(`Created new sheet: ${data.properties.title} (ID: ${data.spreadsheetId})`);

      return {
        id: data.spreadsheetId,
        title: data.properties.title,
        url: data.spreadsheetUrl,
        lastModified: new Date().toISOString(), // Convert to ISO string
      };
    } catch (error) {
      console.error('Failed to create sheet:', error);
      throw new Error('Failed to create new Google Sheet. Please check your permissions and try again.');
    }
  }

  /**
   * Add a contact to a specific Google Sheet
   */
  static async addContactToSheet(sheetId: string, contact: ContactInfo): Promise<void> {
    try {
      const headers = await this.getAuthHeaders();
      
      // Get current user info for "Scanned By" column
      const { AuthService } = await import('./auth');
      const currentUser = await AuthService.getCurrentUser();
      const scannedBy = currentUser?.email || 'Unknown';

      // Prepare row data
      const values = [
        [
          contact.name,
          contact.email,
          contact.phone || '',
          scannedBy,
          new Date().toLocaleString(),
        ],
      ];

      // Append values request body
      const requestBody = {
        values,
        majorDimension: 'ROWS',
      };

      // Use A:A range to append to the next available row
      const range = 'A:A';
      const url = `${SHEETS_API_BASE}/${sheetId}/values/${encodeURIComponent(range)}:append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS`;

      const response = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Sheets Append Error:', response.status, errorText);
        throw new Error(`Failed to add contact to sheet: ${response.status}`);
      }

      const data = await response.json();
      console.log(`Added contact ${contact.name} to sheet successfully. Updated range: ${data.updates?.updatedRange}`);
    } catch (error) {
      console.error('Failed to add contact to sheet:', error);
      
      if (error instanceof Error && error.message.includes('403')) {
        throw new Error('Permission denied. Please ensure the app has access to your Google Sheets.');
      } else if (error instanceof Error && error.message.includes('404')) {
        throw new Error('Google Sheet not found. It may have been deleted or moved.');
      }
      
      throw new Error('Failed to add contact to Google Sheet. Please check your connection and try again.');
    }
  }

  /**
   * Bulk add multiple contacts to a sheet
   */
  static async addContactsToSheet(sheetId: string, contacts: ContactInfo[]): Promise<void> {
    try {
      const headers = await this.getAuthHeaders();
      
      // Get current user info for "Scanned By" column
      const { AuthService } = await import('./auth');
      const currentUser = await AuthService.getCurrentUser();
      const scannedBy = currentUser?.email || 'Unknown';

      // Prepare multiple rows of data
      const values = contacts.map(contact => [
        contact.name,
        contact.email,
        contact.phone || '',
        scannedBy,
        new Date().toLocaleString(),
      ]);

      // Append values request body
      const requestBody = {
        values,
        majorDimension: 'ROWS',
      };

      // Use A:A range to append to the next available row
      const range = 'A:A';
      const url = `${SHEETS_API_BASE}/${sheetId}/values/${encodeURIComponent(range)}:append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS`;

      const response = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify(requestBody),
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Sheets Bulk Append Error:', response.status, errorText);
        throw new Error(`Failed to add contacts to sheet: ${response.status}`);
      }

      const data = await response.json();
      console.log(`Added ${contacts.length} contacts to sheet successfully. Updated range: ${data.updates?.updatedRange}`);
    } catch (error) {
      console.error('Failed to add contacts to sheet:', error);
      throw new Error('Failed to add contacts to Google Sheet. Please check your connection and try again.');
    }
  }

  /**
   * Validate that we can access a specific sheet
   */
  static async validateSheetAccess(sheetId: string): Promise<boolean> {
    try {
      const headers = await this.getAuthHeaders();

      // Try to get basic sheet info
      const url = `${SHEETS_API_BASE}/${sheetId}?fields=properties.title`;

      const response = await fetch(url, {
        method: 'GET',
        headers,
      });

      if (response.ok) {
        const data = await response.json();
        console.log(`Validated access to sheet: ${data.properties?.title}`);
        return true;
      } else {
        console.warn(`Sheet access validation failed: ${response.status}`);
        return false;
      }
    } catch (error) {
      console.error('Sheet access validation failed:', error);
      return false;
    }
  }

  /**
   * Get sheet information
   */
  static async getSheetInfo(sheetId: string): Promise<GoogleSheetInfo | null> {
    try {
      const headers = await this.getAuthHeaders();

      // Get sheet metadata
      const url = `${SHEETS_API_BASE}/${sheetId}?fields=properties,spreadsheetUrl`;

      const response = await fetch(url, {
        method: 'GET',
        headers,
      });

      if (!response.ok) {
        console.error(`Failed to get sheet info: ${response.status}`);
        return null;
      }

      const data = await response.json();

      return {
        id: sheetId,
        title: data.properties?.title || 'Untitled Sheet',
        url: data.spreadsheetUrl,
        lastModified: new Date().toISOString(), // Convert to ISO string
      };
    } catch (error) {
      console.error('Failed to get sheet info:', error);
      return null;
    }
  }
}