# Scan2Sheets Mobile App - Implementation Plan

## Overview
A React Native mobile app for conference lead collection that allows users to authenticate with Google, select/create Google Sheets, scan QR codes with attendee information, and automatically add rows to the selected sheet.

## Why React Native?

Based on extensive research using Context7 and current 2025 documentation, React Native is the optimal choice because:

1. **Proven OAuth Solutions**: React Native Nitro Google SSO (Trust Score: 8.8/10) provides modern, native Google authentication that addresses the OAuth challenges you experienced with Go/Fyne and Flutter
2. **Mature QR Scanning**: React Native Vision Camera (Trust Score: 10/10) offers robust, performant QR code scanning with MLKit integration
3. **Excellent Sheets API Support**: Multiple proven libraries and approaches for Google Sheets API v4 integration
4. **Cross-platform**: Single codebase for Android/iOS with native performance
5. **Active Ecosystem**: Regular updates and strong community support in 2025

## Technology Stack

### Core Framework
- **React Native 0.75+** - Latest stable version with New Architecture support
- **TypeScript** - For type safety and better development experience

### Authentication
- **react-native-nitro-google-sso** - Modern Google Sign-In with native SDK integration
  - Uses Google Sign-In SDK on iOS
  - Uses Credential Manager on Android
  - Built for React Native's New Architecture

### QR Code Scanning
- **react-native-vision-camera** - High-performance camera with code scanning
  - Built-in MLKit barcode/QR scanning support
  - No additional dependencies needed
  - Supports multiple code formats (extensible for future)

### Google Sheets Integration
- **google-spreadsheet (v5.0.2)** - Simplified Google Sheets API interface
- **googleapis** - Official Google API client for advanced features
- Direct REST API calls for maximum control

### Additional Libraries
- **@react-native-async-storage/async-storage** - Store authentication tokens
- **react-native-paper** - Material Design UI components
- **react-navigation/native** - Navigation between screens

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Auth Screen   │───▶│  Sheet Select   │───▶│  Scanner Screen │
│                 │    │     Screen      │    │                 │
│  Google Login   │    │ List/Create     │    │  QR Scanner     │
│                 │    │   Sheets        │    │ Add to Sheet    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Google APIs Integration                      │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐  │
│  │  Google Auth    │ │ Google Drive    │ │ Google Sheets   │  │
│  │   OAuth2.0      │ │   List Sheets   │ │  Read/Write     │  │
│  └─────────────────┘ └─────────────────┘ └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 1: Project Setup & Authentication
**Duration**: 1-2 days

1. **Initialize React Native Project**
   ```bash
   npx react-native@latest init Scan2Sheets --template react-native-template-typescript
   cd Scan2Sheets
   ```

2. **Install Core Dependencies**
   ```bash
   npm install react-native-nitro-google-sso react-native-nitro-modules
   npm install google-spreadsheet googleapis
   npm install @react-native-async-storage/async-storage
   npm install react-native-paper react-native-vector-icons
   npm install @react-navigation/native @react-navigation/stack
   ```

3. **Google Cloud Console Setup**
   - Create new Google Cloud project
   - Enable Google Sheets API and Google Drive API
   - Create OAuth 2.0 credentials (iOS + Android + Web)
   - Configure OAuth consent screen

4. **Implement Authentication Screen**
   - Google Sign-In button
   - Handle authentication success/failure
   - Store tokens securely with AsyncStorage
   - Auto-login for returning users

### Phase 2: Sheet Management
**Duration**: 2-3 days

1. **Google Sheets API Integration**
   - Configure googleapis client with OAuth tokens
   - Implement sheet listing (from Google Drive)
   - Implement sheet creation with custom names
   - Test read/write permissions

2. **Sheet Selection Screen**
   - List user's accessible sheets
   - Search/filter functionality
   - "Create New Sheet" option with name input
   - Remember last selected sheet

3. **Sheet Operations**
   - Create sheets with proper headers (Name, Email, Timestamp)
   - Append rows to selected sheet
   - Handle API errors gracefully
   - Offline queue for failed requests

### Phase 3: QR Code Scanner
**Duration**: 2-3 days

1. **Camera Integration**
   ```bash
   npm install react-native-vision-camera
   ```
   - Configure Android permissions
   - Set up iOS camera usage description
   - Enable MLKit barcode scanning in gradle.properties

2. **QR Scanner Screen**
   - Full-screen camera view with overlay
   - Real-time QR code detection
   - Visual feedback for successful scans
   - Manual entry fallback option

3. **Data Parsing & Validation**
   - Start with assumed format: "Name: John Doe, Email: john@example.com"
   - Extensible parser for future formats (JSON, vCard, etc.)
   - Input validation and error handling
   - Duplicate detection (optional)

### Phase 4: UI/UX Polish
**Duration**: 1-2 days

1. **Material Design Implementation**
   - Consistent theming with react-native-paper
   - Loading states and error messages
   - Success confirmations
   - Dark mode support

2. **Navigation Flow**
   - Smooth transitions between screens
   - Back navigation handling
   - Deep linking support (future)

3. **Accessibility**
   - Screen reader support
   - High contrast mode
   - Large text support

### Phase 5: Testing & Deployment
**Duration**: 1-2 days

1. **Testing**
   - Unit tests for data parsing
   - Integration tests for Sheets API
   - Manual testing on Android device
   - Edge case handling (no internet, permission denials)

2. **Android APK Build**
   ```bash
   cd android
   ./gradlew assembleRelease
   ```
   - Configure signing for release builds
   - Generate APK for testing
   - Test installation on target devices

3. **Documentation**
   - User setup instructions
   - Developer documentation
   - Troubleshooting guide

## Key Configuration Files

### Android Permissions (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Enable Code Scanner (`android/gradle.properties`)
```properties
VisionCamera_enableCodeScanner=true
```

### Google Services Setup
- Download `google-services.json` from Firebase Console
- Place in `android/app/` directory
- Configure OAuth client IDs for Android/iOS/Web

## Authentication Flow Solution

This addresses your previous OAuth challenges:

1. **Native SDK Integration**: Uses platform-native Google Sign-In SDKs instead of web-based OAuth
2. **Simplified Configuration**: Single configuration object with client IDs
3. **Token Management**: Automatic token refresh and secure storage
4. **Error Handling**: Clear error messages and retry mechanisms

```typescript
// Example authentication setup
import NitroGoogleSSO from 'react-native-nitro-google-sso';

NitroGoogleSSO.configure({
  iosClientId: 'YOUR_IOS_CLIENT_ID',
  webClientId: 'YOUR_WEB_CLIENT_ID',
  hostedDomain: 'example.com' // Optional: restrict to domain
});

const signIn = async () => {
  try {
    const user = await NitroGoogleSSO.signIn();
    if (user) {
      // Store tokens and proceed to app
      await AsyncStorage.setItem('userTokens', JSON.stringify(user));
      navigation.navigate('SheetSelect');
    }
  } catch (error) {
    console.error('Authentication failed:', error);
  }
};
```

## QR Code Format Strategy

**Phase 1 Format** (Assumed):
```
Name: John Doe, Email: john@example.com
```

**Extensible Parser Design**:
```typescript
interface ContactInfo {
  name: string;
  email: string;
  // Extensible for future fields
  company?: string;
  phone?: string;
}

class QRParser {
  static parse(qrData: string): ContactInfo {
    // Try different parsing strategies
    if (this.isJSON(qrData)) return this.parseJSON(qrData);
    if (this.isVCard(qrData)) return this.parseVCard(qrData);
    return this.parseSimpleFormat(qrData); // Current format
  }
  
  // Individual parsing methods...
}
```

## Security Considerations

1. **Token Storage**: Use encrypted AsyncStorage for OAuth tokens
2. **API Keys**: Store in secure environment variables
3. **Permissions**: Request only necessary permissions
4. **HTTPS**: All API calls use HTTPS
5. **Input Validation**: Sanitize QR code data before sheet insertion

## Future Enhancements

1. **Batch Operations**: Queue multiple scans for bulk upload
2. **Advanced QR Formats**: Support vCard, JSON, custom formats
3. **Analytics**: Track scan success rates and usage patterns
4. **Offline Mode**: Cache scans when internet unavailable
5. **Export Options**: CSV download, email integration
6. **Multi-language**: Internationalization support
7. **App Store**: Publish to Google Play and Apple App Store

## Success Metrics

- ✅ Successful Google authentication without OAuth issues
- ✅ Reliable QR code scanning in various lighting conditions
- ✅ Fast sheet operations (< 2 seconds per scan)
- ✅ Stable performance during conference usage
- ✅ Easy APK installation and setup for users

## Estimated Timeline

**Total**: 7-10 days for MVP
- **Setup & Auth**: 1-2 days
- **Sheet Management**: 2-3 days  
- **QR Scanner**: 2-3 days
- **Polish & Testing**: 2-3 days

This plan addresses your previous OAuth challenges with proven, modern solutions while providing a solid foundation for future enhancements.