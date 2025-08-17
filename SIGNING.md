# App Signing Setup

## Quick Answer
**No, the SHA-1 won't change during development** if you follow this setup.

## Current Setup (Temporary)
- GitHub Actions uses a debug keystore
- SHA-1: `85:2E:B4:F6:03:61:AD:CD:D3:BE:12:AF:8A:B3:74:33:DF:98:8D:0A`
- This works but isn't ideal for production

## Production Setup (Recommended)

### 1. Generate Release Keystore (One-time)
```bash
# Run locally
KEYSTORE_PASSWORD="your-secure-password" ./generate_keystore.sh
```

### 2. Add to GitHub Secrets
1. Convert keystore to base64:
   ```bash
   base64 -i qr-scanner-release.keystore | pbcopy
   ```
2. Go to GitHub repo → Settings → Secrets → Actions
3. Add these secrets:
   - `KEYSTORE_BASE64`: Paste the base64 content
   - `KEYSTORE_PASSWORD`: Your keystore password
   - `KEY_ALIAS`: `qr-scanner`

### 3. Update Google Cloud Console
Add the new SHA-1 from your release keystore to:
- https://console.cloud.google.com/apis/credentials
- Create/edit Android OAuth client with the new SHA-1

### 4. Update GitHub Actions Workflow
The workflow will use your release keystore instead of debug keys.

## Benefits
- ✅ SHA-1 never changes
- ✅ More secure than debug keys
- ✅ Ready for Google Play Store
- ✅ Consistent across all builds
- ✅ No expiration issues

## For Development
Your local debug keystore (for `flutter run`) has a different SHA-1:
- `D7:00:35:FC:05:61:8D:5A:27:85:C4:EF:3E:01:07:5B:7B:FA:EA:58`
- This also stays constant unless you delete `~/.android/debug.keystore`