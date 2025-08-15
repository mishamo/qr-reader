# Quick Setup for misha-project-469120

## Step 1: Enable APIs

Go to these links and click "Enable":

1. [Enable Google Sheets API](https://console.cloud.google.com/apis/library/sheets.googleapis.com?project=misha-project-469120)
2. [Enable Google Drive API](https://console.cloud.google.com/apis/library/drive.googleapis.com?project=misha-project-469120)

## Step 2: Create Service Account

1. Go to: https://console.cloud.google.com/iam-admin/serviceaccounts?project=misha-project-469120
2. Click **"+ CREATE SERVICE ACCOUNT"**
3. Fill in:
   - Service account name: `qr-scanner`
   - Service account ID: `qr-scanner` (auto-fills)
   - Description: `QR Scanner App Service Account`
4. Click **"CREATE AND CONTINUE"**
5. Skip the optional steps - click **"DONE"**

## Step 3: Download Credentials

1. Click on the service account you just created (`qr-scanner@misha-project-469120.iam.gserviceaccount.com`)
2. Go to **"KEYS"** tab
3. Click **"ADD KEY"** → **"Create new key"**
4. Choose **JSON** format
5. Click **"CREATE"**
6. Save the downloaded file as `credentials.json` in this project folder (next to main.go)

## Step 4: Share a Google Sheet with the Service Account

1. Create a new Google Sheet or open an existing one
2. Click the **Share** button
3. Add this email: `qr-scanner@misha-project-469120.iam.gserviceaccount.com`
4. Give it **Editor** access
5. Click **Send**

## Step 5: Test the App

```bash
# Build and run
go build -o qr-scanner-app main.go
./qr-scanner-app
```

The app will automatically detect `credentials.json` and use service account mode - no login required!

## How It Works

- All users of the app will write to sheets owned by your service account
- No individual Google login needed
- The service account email (`qr-scanner@misha-project-469120.iam.gserviceaccount.com`) appears as the "Scanner Email" in sheets
- You control which sheets the app can access by sharing them with the service account

## Troubleshooting

If you see "Service account init failed":
- Check that `credentials.json` is in the project root
- Verify APIs are enabled
- Make sure the JSON file is valid

If sheets aren't updating:
- Ensure the sheet is shared with `qr-scanner@misha-project-469120.iam.gserviceaccount.com`
- Check that the service account has Editor permissions