# Fix Google Sign-In Authentication

## Problem
Google Sign-In fails with "Sign in cancelled or failed" error

## Root Cause
The SHA-1 fingerprints from your Android development environment are not registered in Google Cloud Console.

## Your SHA-1 Fingerprints

### Local Debug APK SHA-1 (for local testing):
```
D7:00:35:FC:05:61:8D:5A:27:85:C4:EF:3E:01:07:5B:7B:FA:EA:58
```

### GitHub Actions Release APK SHA-1 (for downloaded APKs):
```
CB:FF:A6:8E:6F:97:47:F5:12:A3:52:30:EE:AD:9E:CD:60:2D:8C:0C
```

### Package Name:
```
com.mishamo.qr_scanner
```

### OAuth Client ID:
```
65444604303-msum8l55m5evbau52mfcdcsb7e4o8f1j.apps.googleusercontent.com
```

## Steps to Fix

### 1. Go to Google Cloud Console
Visit: https://console.cloud.google.com/apis/credentials

### 2. Select Your Project
Make sure you're in the "qr-scanner-conference" project

### 3. Find Your Android OAuth Client
Look for the OAuth 2.0 Client ID that matches:
- Type: Android
- Client ID: `65444604303-msum8l55m5evbau52mfcdcsb7e4o8f1j.apps.googleusercontent.com`

### 4. Add SHA-1 Fingerprints
Click on the client to edit it and add BOTH fingerprints:
- **Package name**: `com.mishamo.qr_scanner` (should already be there)
- **SHA-1 certificate fingerprint #1**: `D7:00:35:FC:05:61:8D:5A:27:85:C4:EF:3E:01:07:5B:7B:FA:EA:58` (for local debug)
- **SHA-1 certificate fingerprint #2**: `CB:FF:A6:8E:6F:97:47:F5:12:A3:52:30:EE:AD:9E:CD:60:2D:8C:0C` (for CI/GitHub releases)

Note: You can add multiple SHA-1 fingerprints to the same OAuth client.

### 5. Save Changes
Click "Save" at the bottom

### 6. Wait 5 Minutes
Google needs a few minutes to propagate the changes

### 7. Test Again
Try signing in again on your app

## Alternative: Create New Android OAuth Client

If the above doesn't work, create a new Android OAuth client:

1. Click "Create Credentials" → "OAuth client ID"
2. Choose "Android" as application type
3. Enter:
   - Name: "QR Scanner Android"
   - Package name: `com.mishamo.qr_scanner`
   - SHA-1: `D7:00:35:FC:05:61:8D:5A:27:85:C4:EF:3E:01:07:5B:7B:FA:EA:58`
4. Click "Create"
5. Edit the created client and add the second SHA-1:
   - SHA-1: `CB:FF:A6:8E:6F:97:47:F5:12:A3:52:30:EE:AD:9E:CD:60:2D:8C:0C`
6. Download the new `google-services.json`
7. Replace `android/app/google-services.json` with the downloaded file
8. Rebuild the app

## Important: Different SHA-1 for Different Build Environments

- **Local builds** (flutter run, flutter build apk): Use your local debug keystore SHA-1
- **GitHub Actions builds**: Use a different keystore, hence different SHA-1
- **Both must be registered** in Google Cloud Console for sign-in to work

To use a proper release keystore later:
1. Generate a release keystore
2. Get its SHA-1 fingerprint
3. Add it to Google Cloud Console
4. Update `android/app/build.gradle` to use the release keystore

## Verify SHA-1 from APK

To verify the SHA-1 of your installed APK:
```bash
# For APK file
keytool -printcert -jarfile app-release.apk | grep SHA1

# For installed app (requires adb)
adb shell pm list packages | grep mishamo
adb shell pm path com.mishamo.qr_scanner
adb pull <path_from_above> app.apk
keytool -printcert -jarfile app.apk | grep SHA1
```