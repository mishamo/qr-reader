#!/bin/bash

echo "QR Scanner OAuth Configuration"
echo "=============================="
echo ""
echo "Please have your Google OAuth2 credentials ready."
echo "Get them from: https://console.cloud.google.com/apis/credentials"
echo ""

read -p "Enter your Client ID (ends with .apps.googleusercontent.com): " CLIENT_ID
read -p "Enter your Client Secret: " CLIENT_SECRET

# Backup original file
cp internal/auth/manager.go internal/auth/manager.go.bak

# Update the credentials
sed -i '' "s/YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com/$CLIENT_ID/g" internal/auth/manager.go
sed -i '' "s/YOUR_GOOGLE_CLIENT_SECRET/$CLIENT_SECRET/g" internal/auth/manager.go

echo ""
echo "✅ Configuration updated!"
echo ""
echo "Next steps:"
echo "1. Test on desktop: go run main.go"
echo "2. Build for Android: make build-android-debug"
echo ""
echo "If you need to revert, run: mv internal/auth/manager.go.bak internal/auth/manager.go"