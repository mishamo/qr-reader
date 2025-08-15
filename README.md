# QR Scanner - Distributed Conference Badge Scanner

A mobile app built with Fyne for scanning QR codes at conferences and events, with automatic synchronization to Google Sheets.

## Features

- **Distributed Scanning**: Multiple users can scan to the same Google Sheet
- **Service Account Auth**: No individual Google logins required
- **Smart Duplicate Handling**: Configurable options for handling duplicate scans
- **Cross-Platform**: Works on Android (iOS support planned)
- **Data Parsing**: Automatically parses JSON, CSV, and key-value QR formats
- **Shared Sheets**: All scanners write to your Google Sheets

## Prerequisites

1. Go 1.25 or higher
2. Fyne CLI tool: `go install fyne.io/tools/cmd/fyne@latest`
3. Google Cloud Project with billing enabled
4. Service account credentials

## Setup

### 1. Google Cloud Configuration

This app uses service account authentication with project `misha-project-469120`:

1. **Service Account**: `qr-scanner@misha-project-469120.iam.gserviceaccount.com`
2. **Required APIs**: 
   - Google Sheets API (enabled)
   - Google Drive API (enabled)
3. **Credentials**: Place `credentials.json` in project root

### 2. Create and Share Sheets

**Important**: Service accounts cannot create Google Sheets due to Drive storage limitations.

1. Create a sheet manually at https://sheets.new
2. Share it with: `qr-scanner@misha-project-469120.iam.gserviceaccount.com` (Editor permission)
3. Copy the sheet ID from the URL
4. Use the sheet in the app

**Test Sheet Available**: 
- ID: `1y6iMUDynDcKvoX4x29yoqUSRvwVcyRSAWBYHa35hZGA`
- Use "Use Test Sheet" button in the app

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

1. Launch the app (automatically uses service account)
2. Go to "Sheets" tab
3. Either:
   - Click "Use Test Sheet" for quick testing
   - Click "Select Sheet" to choose from shared sheets

### Using Sheets

1. **Create Sheet**: Manually at https://sheets.new
2. **Share Sheet**: With `qr-scanner@misha-project-469120.iam.gserviceaccount.com`
3. **Select in App**: Use "Select Sheet" button
4. **Start Scanning**: All data goes to selected sheet

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

### "Failed to create sheet" Error
- Service accounts cannot create Google Sheets (0 GB Drive quota)
- Create sheets manually and share with the service account email

### Sheet Not Appearing
- Ensure sheet is shared with `qr-scanner@misha-project-469120.iam.gserviceaccount.com`
- Grant "Editor" permission when sharing
- Refresh the sheet list in the app

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