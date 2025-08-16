#!/bin/bash

# OAuth Configuration Script for QR Scanner

echo "═══════════════════════════════════════════════════════"
echo "          QR Scanner OAuth Configuration"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "First, create OAuth credentials in Google Cloud Console:"
echo "1. Go to: https://console.cloud.google.com/apis/credentials"
echo "2. Click '+ CREATE CREDENTIALS' → 'OAuth client ID'"
echo "3. Choose 'Web application'"
echo "4. Add redirect URI: http://localhost:8080/callback"
echo "5. Copy the Client ID and Client Secret"
echo ""
echo "═══════════════════════════════════════════════════════"
echo ""

read -p "Enter your OAuth Client ID (ends with .apps.googleusercontent.com): " CLIENT_ID
read -p "Enter your OAuth Client Secret: " CLIENT_SECRET

if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
    echo "Error: Both Client ID and Client Secret are required"
    exit 1
fi

# Update the auth manager file
AUTH_FILE="internal/auth/manager.go"

# Use sed to replace the placeholders
sed -i.bak "s|YOUR_GOOGLE_CLIENT_ID\.apps\.googleusercontent\.com|$CLIENT_ID|g" "$AUTH_FILE"
sed -i.bak "s|YOUR_GOOGLE_CLIENT_SECRET|$CLIENT_SECRET|g" "$AUTH_FILE"

# Remove backup file
rm -f "${AUTH_FILE}.bak"

echo ""
echo "✅ OAuth credentials configured successfully!"
echo ""
echo "You can now test the app locally:"
echo "  make run"
echo ""
echo "Or build for Android:"
echo "  make build-android"
echo ""