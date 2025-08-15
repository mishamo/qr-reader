#!/bin/bash

echo "This will grant Editor role to your service account"
echo "Run this command in Google Cloud Shell or with gcloud CLI installed:"
echo ""
echo "gcloud projects add-iam-policy-binding misha-project-469120 \\"
echo "  --member='serviceAccount:qr-scanner@misha-project-469120.iam.gserviceaccount.com' \\"
echo "  --role='roles/editor'"
echo ""
echo "Or do it manually in the console:"
echo "1. Click '+ GRANT ACCESS' button"
echo "2. Enter: qr-scanner@misha-project-469120.iam.gserviceaccount.com"
echo "3. Select role: Basic → Editor"
echo "4. Click SAVE"