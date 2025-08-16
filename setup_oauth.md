# Setting Up OAuth for QR Scanner App

## Quick Setup (5 minutes)

### 1. Create OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project (misha-project-469120)
3. Navigate to **APIs & Services** → **Credentials**
4. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
5. Select **Application type**: Web application
6. Name: "QR Scanner App"
7. Add Authorized redirect URIs:
   - `http://localhost:8080/callback`
   - For mobile, OAuth will use the system browser and redirect to localhost
8. Click **CREATE**
9. Copy the Client ID and Client Secret

### 2. Enable Required APIs

Make sure these are enabled:
- Google Sheets API
- Google Drive API

### 3. Update the App

Replace the values in `internal/auth/manager.go`:
- `YOUR_GOOGLE_CLIENT_ID` with your Client ID
- `YOUR_GOOGLE_CLIENT_SECRET` with your Client Secret

### 4. Build and Deploy

```bash
git add .
git commit -m "Add OAuth credentials"
git push origin master
```

## How It Works

1. **Users sign in** with their own Google account
2. **Create or select sheets** from their own Drive
3. **Share sheet** with team members via Google Sheets sharing
4. **Team members sign in** and select the shared sheet
5. **Everyone scans** to the same sheet

## No More credentials.json!

- Each user authenticates with their own Google account
- No need to distribute credentials.json files
- Works with any Google account
- Sheets are owned by users, not service accounts