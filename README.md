# 📱 Scan2Sheets

**Professional conference lead collection made simple.**

Scan2Sheets is a React Native mobile app that allows you to scan QR codes containing contact information and automatically add them to Google Sheets. Perfect for conferences, networking events, trade shows, and any scenario where you need to quickly collect and organize contact data.

[![Build Status](https://github.com/mishamo/scan2sheets/actions/workflows/build.yml/badge.svg)](https://github.com/mishamo/scan2sheets/actions)
[![Release](https://img.shields.io/github/v/release/mishamo/scan2sheets)](https://github.com/mishamo/scan2sheets/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## ✨ Features

🔥 **Core Functionality:**
- **📱 QR Code Scanner**: High-performance camera-based QR code scanning
- **📊 Google Sheets Integration**: Seamless integration with your Google Sheets
- **🔐 Secure Authentication**: Google OAuth 2.0 for safe access to your data
- **📋 Multiple QR Formats**: Support for JSON, CSV, and vCard contact formats
- **🎨 Professional UI**: Material Design with custom branding

⚡ **Smart Features:**
- **Auto-Skip Authentication**: Remembers your login status
- **Sheet Selection**: Choose from existing sheets or create new ones
- **Real-time Sync**: Contacts appear immediately in your Google Sheets
- **Error Handling**: Robust error recovery and user feedback
- **Offline-First**: Graceful handling of network issues

## 📱 Installation

### Option 1: Download APK (Recommended)
1. Go to [Releases](https://github.com/mishamo/scan2sheets/releases/latest)
2. Download the latest `app-release.apk`
3. Enable "Install from Unknown Sources" in Android settings
4. Install the APK and grant camera permissions
5. Sign in with your Google account and start scanning!

### Option 2: Build from Source
```bash
# Clone the repository
git clone https://github.com/mishamo/scan2sheets.git
cd scan2sheets

# Install dependencies
npm install

# For Android
npx react-native run-android

# For iOS (requires Xcode and CocoaPods)
cd ios && pod install && cd ..
npx react-native run-ios
```

## 🚀 Usage

### 1. **Authentication**
- Launch the app and sign in with your Google account
- Grant permissions for Google Sheets and camera access

### 2. **Select or Create a Sheet**
- Choose from your existing Google Sheets
- Or create a new sheet with a custom name
- Sheet selection is remembered for future sessions

### 3. **Scan QR Codes**
- Point your camera at a QR code containing contact information
- The app automatically detects and parses the contact data
- Review the parsed information before adding to your sheet

### 4. **View Results**
- Contacts are instantly added to your selected Google Sheet
- Tap "View Sheet" to open your Google Sheet in the browser
- Track who scanned each contact and when

## 📋 Supported QR Code Formats

Scan2Sheets supports multiple QR code formats for maximum compatibility:

### **JSON Format** (Recommended)
```json
{
  "name": "John Doe",
  "email": "john@example.com", 
  "phone": "123-456-7890"
}
```

### **Simple CSV Format**
```
John Doe,john@example.com,123-456-7890
```

### **vCard Format**
```
BEGIN:VCARD
VERSION:3.0
FN:John Doe
EMAIL:john@example.com
TEL:123-456-7890
END:VCARD
```

## 📊 Google Sheets Structure

When you create a new sheet or scan contacts, the following columns are automatically created:

| Name | Email | Phone | Scanned By | Scanned At |
|------|-------|-------|------------|------------|
| John Doe | john@example.com | 123-456-7890 | user@example.com | 8/25/2025, 2:30:15 PM |

## 🛠️ Development

### Prerequisites
- Node.js 18+ 
- React Native CLI
- Android Studio (for Android)
- Xcode (for iOS)
- Google Cloud Console project with Sheets API enabled

### Setup
```bash
# Clone and install
git clone https://github.com/mishamo/scan2sheets.git
cd scan2sheets
npm install

# Android setup
npx react-native run-android

# iOS setup  
cd ios && pod install && cd ..
npx react-native run-ios
```

### Google Cloud Configuration
1. Create a Google Cloud Console project
2. Enable Google Sheets API and Google Drive API
3. Create OAuth 2.0 credentials (Web and Android)
4. Configure OAuth consent screen
5. Add your SHA-1 fingerprints for Android

Detailed setup instructions in [PLAN.md](PLAN.md).

## 🚀 CI/CD & Releases

### Automated Builds
Every push triggers automated builds for both Android and iOS:
- **Android APK**: Built with optimized Gradle caching (~3-5 minutes)
- **iOS App**: Built for iOS Simulator testing (~20 minutes)
- **Artifacts**: Available for download from GitHub Actions

### Creating Releases
Releases are automatically created when version tags are pushed:

```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

This automatically:
1. Builds optimized Android APK
2. Creates GitHub release with professional description  
3. Uploads APK as downloadable asset
4. Generates comprehensive release notes

## 🏗️ Architecture

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

## 📦 Built With

- **React Native 0.81** - Cross-platform mobile framework
- **@react-native-google-signin/google-signin** - Google OAuth authentication  
- **react-native-camera-kit** - Camera and QR code scanning
- **react-native-paper** - Material Design UI components
- **Google Sheets API v4** - Direct REST API integration
- **Google Drive API v3** - Sheet listing and management

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Claude Code](https://claude.ai/code) - AI-powered development assistant
- Icons and design inspiration from Material Design
- QR code scanning powered by react-native-camera-kit
- Google APIs for seamless Sheets integration

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/mishamo/scan2sheets/issues)
- **Discussions**: [GitHub Discussions](https://github.com/mishamo/scan2sheets/discussions)
- **Documentation**: [Project Wiki](https://github.com/mishamo/scan2sheets/wiki)

---

<div align="center">

**Made with ❤️ for the conference and networking community**

[Download Latest Release](https://github.com/mishamo/scan2sheets/releases/latest) • [View Documentation](PLAN.md) • [Report Bug](https://github.com/mishamo/scan2sheets/issues)

</div>