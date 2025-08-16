# QR Scanner - Distributed Conference Badge Scanner

A mobile app built with Fyne for scanning QR codes at conferences and events, with automatic synchronization to Google Sheets.

## Features

- **Individual Google Sign-in**: Each user signs in with their own Google account
- **Create & Share Sheets**: Create sheets in your Drive, share with team
- **Collaborative Scanning**: Multiple users scan to the same shared sheet
- **Smart Duplicate Handling**: Configurable options for handling duplicate scans
- **Cross-Platform**: Works on Android (iOS support planned)
- **Data Parsing**: Automatically parses JSON, CSV, and key-value QR formats

## Prerequisites

1. Go 1.25 or higher
2. Fyne CLI tool: `go install fyne.io/tools/cmd/fyne@latest`
3. Google Cloud Project with OAuth2 credentials

## Setup

### 1. Google OAuth Configuration

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create or select a project
3. Navigate to **APIs & Services** → **Credentials**
4. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
5. Select **Application type**: Web application
6. Add Authorized redirect URI: `http://localhost:8080/callback`
7. Copy the Client ID and Client Secret

### 2. Configure the App

Edit `internal/auth/manager.go` and replace:
```go
func getClientID() string {
    return "YOUR_CLIENT_ID.apps.googleusercontent.com"
}
func getClientSecret() string {
    return "YOUR_CLIENT_SECRET"
}
```

### 3. Enable APIs

In Google Cloud Console, enable:
- Google Sheets API
- Google Drive API

### 3. Build and Deploy

#### Option A: GitHub Actions (Recommended)
Push to GitHub and let Actions build the APK:
```bash
git push origin master
# APK will be available in Actions artifacts
```

#### Option B: Local Build
```bash
# Run build script (requires Android SDK/NDK)
./build_android.sh

# Or manually:
fyne package --target android --app-id com.qorda.qrscanner --name "QR Scanner" --icon Icon.png
```

#### Option C: Desktop Testing
```bash
go build -o qr-scanner-app main.go
./qr-scanner-app
```

### 4. Install on Android Device

```bash
# Via ADB (with USB debugging enabled)
adb install "QR Scanner.apk"

# Or transfer APK to device and install manually
# (Enable "Install from Unknown Sources" in settings)
```

## Usage

### First Time Setup

1. Launch the app
2. Click "Sign in with Google"
3. Authorize the app to access your Google Sheets
4. You're ready to scan!

### Creating a Shared Sheet

1. In the app, go to "Sheets" tab
2. Click "Create New Sheet"
3. Click "Share Current Sheet" to get the link
4. Share the link with team members
5. Team members sign in and select the same sheet

### Joining a Shared Sheet

1. Sign in with your Google account
2. Someone shares a sheet with you (via Google Sheets sharing)
3. Go to "Sheets" tab → "Select Existing Sheet"
4. Choose the shared sheet from the list
5. Start scanning!

### Scanning

1. Tap "Start Scanning" on the main screen
2. Point camera at QR codes
3. Data is automatically saved to the active sheet
4. View recent scans in the list below

### Duplicate Handling Options

- **Allow Duplicates**: All scans are recorded
- **Skip Duplicates**: Ignore if already scanned
- **Update Existing**: Update the timestamp for re-scans

## Development

### Run Tests

```bash
go test ./...
```

### Format Code

```bash
go fmt ./...
```

### Desktop Testing

```bash
go run main.go
```

## Architecture

```
├── main.go                 # Entry point
├── internal/
│   ├── auth/              # Google OAuth2 authentication
│   ├── scanner/           # QR code scanning logic
│   ├── sheets/            # Google Sheets API integration
│   ├── storage/           # Local preferences storage
│   └── ui/                # Fyne UI components
├── build/                 # Android build files
└── assets/                # Icons and resources
```

## Data Format Support

The app automatically detects and parses:

- **JSON**: `{"name": "John Doe", "email": "john@example.com"}`
- **CSV**: `John Doe,john@example.com,Company Name`
- **Key-Value**: `name:John Doe\nemail:john@example.com`
- **Plain Text**: Stored as-is in a single column

## Troubleshooting

### Authentication Issues
- Make sure OAuth credentials are correctly configured
- Verify redirect URI is exactly: `http://localhost:8080/callback`
- Check that both Sheets and Drive APIs are enabled

### Sheet Not Appearing
- Ensure the sheet is shared with your Google account
- Check your Google account has Editor permission
- Try refreshing the sheet list in the app

### Camera Not Working
- Grant camera permissions when prompted
- Ensure good lighting for QR code visibility
- Current implementation uses mock camera for testing

### APK Won't Install
- Enable "Install from Unknown Sources" in Android settings
- Ensure device architecture matches APK build

## Roadmap

- [x] Service account authentication
- [x] Google Sheets integration
- [x] Android build pipeline
- [x] GitHub Actions CI/CD
- [ ] Real camera implementation
- [ ] iOS support and TestFlight distribution  
- [ ] Offline queue and batch sync
- [ ] Custom field mapping UI
- [ ] Analytics dashboard

## License

MIT License - See LICENSE file for details

## Contributing

Pull requests welcome! Please ensure:
- Code is formatted with `gofmt`
- Tests pass with `go test ./...`
- Follow existing code style patterns