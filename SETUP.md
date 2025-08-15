# QR Scanner Setup Guide

## Google OAuth2 Setup

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click "Select a project" → "New Project"
3. Enter project name (e.g., "QR Scanner") and create

### Step 2: Enable Required APIs

1. In the console, go to "APIs & Services" → "Library"
2. Search and enable:
   - Google Sheets API
   - Google Drive API

### Step 3: Create OAuth2 Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth client ID"
3. If prompted, configure OAuth consent screen:
   - User Type: External
   - App name: QR Scanner
   - User support email: Your email
   - Developer contact: Your email
   - Scopes: Add these scopes:
     - .../auth/spreadsheets
     - .../auth/drive.file
     - .../auth/userinfo.email
     - .../auth/userinfo.profile

4. For OAuth client ID:
   - Application type: **Web application**
   - Name: QR Scanner Web
   - Authorized redirect URIs: Add `http://localhost:8080/callback`
   - Click "Create"

5. Download the credentials JSON or copy:
   - Client ID
   - Client Secret

### Step 4: Configure the App

Edit `internal/auth/manager.go` and update these functions:

```go
func getClientID() string {
    return "YOUR_CLIENT_ID.apps.googleusercontent.com"
}

func getClientSecret() string {
    return "YOUR_CLIENT_SECRET"
}
```

### Step 5: Add Test Users (if using External user type)

1. Go to "OAuth consent screen" → "Test users"
2. Add your email and any team members who will test
3. Save

## Building for Android

### Prerequisites

1. Install Android SDK
2. Install Fyne: `go install fyne.io/fyne/v2/cmd/fyne@latest`

### Build APK

```bash
# Debug build (for testing)
make build-android-debug

# Release build
make build-android
```

### Install on Device

#### Option 1: ADB
```bash
adb install -r QRScanner.apk
```

#### Option 2: Manual
1. Transfer APK to device
2. Enable "Install from unknown sources" in Settings
3. Open APK file on device

## Testing on Desktop

```bash
# Run with mobile simulation
go run -tags mobile main.go

# Or normal desktop mode
go run main.go
```

## Troubleshooting

### "invalid_client" Error
- Verify Client ID and Secret are correctly copied
- Ensure redirect URI exactly matches: `http://localhost:8080/callback`
- Check that APIs are enabled in Google Cloud Console

### Port 8080 Already in Use
```bash
# Kill process on port 8080
lsof -i :8080 | grep LISTEN | awk '{print $2}' | xargs kill -9
```

### Authentication Opens Wrong Browser
- The app will try to open your default browser
- Copy the URL and open in Chrome if needed

## Next Steps

1. Configure OAuth credentials
2. Test on desktop first
3. Build APK for Android
4. Deploy to test devices
5. Share Google Sheets with team members