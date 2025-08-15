package sheets

import (
	"encoding/csv"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"google.golang.org/api/drive/v3"
	"google.golang.org/api/sheets/v4"
	"github.com/qorda/qr-scanner/internal/auth"
)

type Manager struct {
	auth         *auth.Manager
	service      *sheets.Service
	driveService *drive.Service
	activeSheet  *Sheet
}

type Sheet struct {
	ID            string
	Name          string
	URL           string
	Columns       []string
	DuplicateMode DuplicateMode
	LastScanned   time.Time
	RowData       [][]string
}

type DuplicateMode int

const (
	AllowDuplicates DuplicateMode = iota
	SkipDuplicates
	UpdateExisting
)

func NewManager(authManager *auth.Manager) *Manager {
	return &Manager{
		auth: authManager,
	}
}

func (m *Manager) ensureServices() error {
	if m.service == nil {
		service, err := m.auth.GetSheetsService()
		if err != nil {
			return err
		}
		m.service = service
	}

	if m.driveService == nil {
		driveService, err := m.auth.GetDriveService()
		if err != nil {
			return err
		}
		m.driveService = driveService
	}

	return nil
}

func (m *Manager) CreateSheet(name string) error {
	// Service accounts can't create sheets due to Drive storage limitations
	// Instead, return an informative error
	return fmt.Errorf("service accounts cannot create new sheets. Please create a sheet manually in Google Drive and share it with: qr-scanner@misha-project-469120.iam.gserviceaccount.com")
}

func (m *Manager) ShareSheet(sheetID string, email string) error {
	if err := m.ensureServices(); err != nil {
		return err
	}

	permission := &drive.Permission{
		Type:         "user",
		Role:         "writer",
		EmailAddress: email,
	}

	_, err := m.driveService.Permissions.Create(sheetID, permission).Do()
	if err != nil {
		return fmt.Errorf("failed to share sheet: %w", err)
	}

	return nil
}

func (m *Manager) ShareSheetWithDomain(sheetID string, domain string) error {
	if err := m.ensureServices(); err != nil {
		return err
	}

	permission := &drive.Permission{
		Type:   "domain",
		Role:   "writer",
		Domain: domain,
	}

	_, err := m.driveService.Permissions.Create(sheetID, permission).Do()
	if err != nil {
		return fmt.Errorf("failed to share sheet with domain: %w", err)
	}

	return nil
}

func (m *Manager) ListSheets() ([]*Sheet, error) {
	if err := m.ensureServices(); err != nil {
		return nil, err
	}

	// List sheets that the service account has access to
	// This will include sheets shared with the service account
	query := "mimeType='application/vnd.google-apps.spreadsheet' and trashed=false"
	fileList, err := m.driveService.Files.List().
		Q(query).
		Fields("files(id, name, webViewLink)").
		PageSize(100).
		Do()
	if err != nil {
		return nil, fmt.Errorf("failed to list sheets: %w", err)
	}

	var sheets []*Sheet
	for _, file := range fileList.Files {
		sheets = append(sheets, &Sheet{
			ID:   file.Id,
			Name: file.Name,
			URL:  file.WebViewLink,
		})
	}
	
	// If no sheets found, provide helpful message
	if len(sheets) == 0 {
		fmt.Println("No sheets found. To use this app:")
		fmt.Println("1. Create a Google Sheet at: https://sheets.new")
		fmt.Println("2. Share it with: qr-scanner@misha-project-469120.iam.gserviceaccount.com")
		fmt.Println("3. Reload this app to see the sheet")
	}

	return sheets, nil
}

func (m *Manager) GetActiveSheet() *Sheet {
	return m.activeSheet
}

func (m *Manager) SetActiveSheet(sheet *Sheet) {
	m.activeSheet = sheet
}

func (m *Manager) AppendScanData(data string) error {
	if m.activeSheet == nil {
		return fmt.Errorf("no active sheet selected")
	}

	if err := m.ensureServices(); err != nil {
		return err
	}

	parsedData := m.parseQRData(data)
	
	if m.activeSheet.DuplicateMode != AllowDuplicates {
		isDuplicate, rowIndex := m.checkForDuplicate(data)
		if isDuplicate {
			if m.activeSheet.DuplicateMode == SkipDuplicates {
				return nil
			} else if m.activeSheet.DuplicateMode == UpdateExisting {
				return m.updateRow(rowIndex, parsedData)
			}
		}
	}

	timestamp := time.Now().Format("2006-01-02 15:04:05")
	userEmail := m.auth.GetUserEmail()

	var values [][]interface{}
	row := []interface{}{timestamp}
	
	for key, value := range parsedData {
		row = append(row, fmt.Sprintf("%s: %s", key, value))
	}
	row = append(row, userEmail, data)
	
	values = append(values, row)

	valueRange := &sheets.ValueRange{
		Values: values,
	}

	_, err := m.service.Spreadsheets.Values.Append(
		m.activeSheet.ID,
		"Scans!A:Z",
		valueRange,
	).ValueInputOption("RAW").Do()
	if err != nil {
		return fmt.Errorf("failed to append data: %w", err)
	}

	m.activeSheet.LastScanned = time.Now()
	return nil
}

func (m *Manager) parseQRData(data string) map[string]string {
	result := make(map[string]string)
	
	var jsonData map[string]interface{}
	if err := json.Unmarshal([]byte(data), &jsonData); err == nil {
		for key, value := range jsonData {
			result[key] = fmt.Sprintf("%v", value)
		}
		return result
	}
	
	if strings.Contains(data, ",") {
		reader := csv.NewReader(strings.NewReader(data))
		if fields, err := reader.Read(); err == nil {
			for i, field := range fields {
				result[fmt.Sprintf("Field%d", i+1)] = field
			}
			return result
		}
	}
	
	if strings.Contains(data, ":") || strings.Contains(data, "=") {
		separator := ":"
		if strings.Contains(data, "=") && !strings.Contains(data, ":") {
			separator = "="
		}
		
		lines := strings.Split(data, "\n")
		for _, line := range lines {
			parts := strings.SplitN(line, separator, 2)
			if len(parts) == 2 {
				key := strings.TrimSpace(parts[0])
				value := strings.TrimSpace(parts[1])
				result[key] = value
			}
		}
		if len(result) > 0 {
			return result
		}
	}
	
	result["data"] = data
	return result
}

func (m *Manager) checkForDuplicate(data string) (bool, int) {
	if m.activeSheet == nil || m.activeSheet.RowData == nil {
		return false, -1
	}

	for i, row := range m.activeSheet.RowData {
		if len(row) > 0 && row[len(row)-1] == data {
			return true, i + 2
		}
	}

	return false, -1
}

func (m *Manager) updateRow(rowIndex int, data map[string]string) error {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	userEmail := m.auth.GetUserEmail()

	var values [][]interface{}
	row := []interface{}{timestamp}
	
	for key, value := range data {
		row = append(row, fmt.Sprintf("%s: %s", key, value))
	}
	row = append(row, userEmail)
	
	values = append(values, row)

	valueRange := &sheets.ValueRange{
		Values: values,
	}

	updateRange := fmt.Sprintf("Scans!A%d:Z%d", rowIndex, rowIndex)
	_, err := m.service.Spreadsheets.Values.Update(
		m.activeSheet.ID,
		updateRange,
		valueRange,
	).ValueInputOption("RAW").Do()
	if err != nil {
		return fmt.Errorf("failed to update row: %w", err)
	}

	return nil
}

func (m *Manager) LoadSheetData() error {
	if m.activeSheet == nil {
		return fmt.Errorf("no active sheet")
	}

	if err := m.ensureServices(); err != nil {
		return err
	}

	resp, err := m.service.Spreadsheets.Values.Get(
		m.activeSheet.ID,
		"Scans!A2:Z",
	).Do()
	if err != nil {
		return fmt.Errorf("failed to load sheet data: %w", err)
	}

	m.activeSheet.RowData = [][]string{}
	for _, row := range resp.Values {
		var stringRow []string
		for _, cell := range row {
			stringRow = append(stringRow, fmt.Sprintf("%v", cell))
		}
		m.activeSheet.RowData = append(m.activeSheet.RowData, stringRow)
	}

	return nil
}

func (m *Manager) SetDuplicateMode(mode DuplicateMode) {
	if m.activeSheet != nil {
		m.activeSheet.DuplicateMode = mode
	}
}