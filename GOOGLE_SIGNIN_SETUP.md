# Google Sign-In Setup Complete ✅

## What I've Fixed

1. **Updated google-services.json** with correct package name: `com.mishamo.qr_scanner`
2. **Built new debug APK** that's ready to test
3. **Pushed changes** to trigger new GitHub Actions build

## IMPORTANT: Update Google Cloud Console

Since your OAuth clients in Google Cloud Console show package name as `com.mishamo.qrreader`, you need to update them to match the app's actual package name.

### For EACH Android OAuth Client:

1. Go to: https://console.cloud.google.com/apis/credentials
2. Click on each Android OAuth client
3. Update the **Package name** from `com.mishamo.qrreader` to:
   ```
   com.mishamo.qr_scanner
   ```
4. Keep the SHA-1 fingerprints as they are
5. Click **Save**

### Your OAuth Clients Should Have:

**Client 1 (Local Debug)**:
- Package name: `com.mishamo.qr_scanner`
- SHA-1: `D7:00:35:FC:05:61:8D:5A:27:85:C4:EF:3E:01:07:5B:7B:FA:EA:58`

**Client 2 (GitHub Actions)**:
- Package name: `com.mishamo.qr_scanner`  
- SHA-1: `CB:FF:A6:8E:6F:97:47:F5:12:A3:52:30:EE:AD:9E:CD:60:2D:8C:0C`

## Testing the App

### Local Debug APK:
```bash
# Install on your device
adb install build/app/outputs/flutter-apk/app-debug.apk

# Or copy the APK to your device and install manually
```

### GitHub Release APK:
- Wait for the CI build to complete
- Download from: https://github.com/mishamo/qr-reader/releases/latest

## Troubleshooting

If sign-in still fails:

1. **Wait 5-10 minutes** after updating Google Cloud Console (changes need to propagate)

2. **Clear app data** on your device:
   - Settings → Apps → QR Scanner → Storage → Clear Data

3. **Verify package name** matches exactly:
   - In Google Cloud Console: `com.mishamo.qr_scanner`
   - In app's build.gradle: `com.mishamo.qr_scanner`
   - Note the underscore, not a dot!

4. **Check SHA-1** matches your build environment:
   ```bash
   # For local debug APK
   ~/Library/Android/sdk/build-tools/36.0.0/apksigner verify --print-certs build/app/outputs/flutter-apk/app-debug.apk | grep SHA-1
   
   # Should show: d70035fc05618d5a2785c4ef3e01075b7bfaea58
   ```

## Success Indicators

✅ "Sign in with Google" button works
✅ Google account picker appears
✅ After selecting account, returns to app
✅ Can create/select Google Sheets
✅ QR code scanning saves to selected sheet

## Next Build

A new GitHub Actions build is running now with the updated configuration.
Check status at: https://github.com/mishamo/qr-reader/actions