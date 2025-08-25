// Navigation types
export type RootStackParamList = {
  Auth: undefined;
  SheetSelect: undefined;
  Scanner: undefined;
};

// Google OAuth types
export interface GoogleUserInfo {
  idToken: string;
  accessToken: string;
  email: string;
  name: string;
  givenName: string;
  familyName: string;
  photoUrl: string;
}

// QR Code types
export interface QRScanResult {
  data: string;
  format: 'QR' | 'manual';
  timestamp: Date;
}

// Contact info parsed from QR codes
export interface ContactInfo {
  name: string;
  email: string;
  // Extensible for future fields
  company?: string;
  phone?: string;
}