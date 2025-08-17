# OAuth Setup Instructions

## You need to do the following:

### 1. Get the Web Application Credentials
In Google Cloud Console:
1. Click on **"QR Scanner App"** (the Web application client, NOT the Android one)
2. Copy the **Client ID** (should look like: 65444604303-mf6a3...apps.googleusercontent.com)  
3. Click **"DOWNLOAD JSON"** or copy the **Client secret**

### 2. Update Local .env File
Edit `.env` and replace with your actual credentials:
```
GOOGLE_CLIENT_ID=your_actual_web_client_id_here
GOOGLE_CLIENT_SECRET=your_actual_web_client_secret_here
```

### 3. Update GitHub Secrets
Go to: https://github.com/mishamo/qr-reader/settings/secrets/actions

Update these secrets with the **Web application** credentials:
- `GOOGLE_CLIENT_ID` - The Web application client ID
- `GOOGLE_CLIENT_SECRET` - The Web application client secret

### 4. Test Locally (Optional)
```bash
./generate_credentials.sh
go build -o qr-scanner-app .
./qr-scanner-app
```

### 5. Push and Create New Release
After updating GitHub secrets, we'll create a new release with the correct credentials.

## Important Notes:
- ✅ Use the **Web application** client (named "QR Scanner App")
- ❌ DO NOT use the Android client (named "QR Scanner Android")
- The Android client doesn't support redirect URIs for web pages
- The Web client supports the https://mishamo.github.io/qr-reader/oauth-callback redirect