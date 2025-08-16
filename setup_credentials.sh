#!/bin/bash

echo "==================================="
echo "QR Scanner OAuth Credential Setup"
echo "==================================="
echo ""

# Check if .env exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing .env file."
        exit 0
    fi
fi

# Prompt for credentials
echo "Enter your OAuth credentials from Google Cloud Console:"
echo "(https://console.cloud.google.com/apis/credentials?project=misha-project-469120)"
echo ""

read -p "Client ID: " CLIENT_ID
read -p "Client Secret: " CLIENT_SECRET

# Validate inputs
if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
    echo "❌ Error: Client ID and Secret are required!"
    exit 1
fi

# Create .env file
cat > .env << EOF
# Google OAuth Credentials
GOOGLE_CLIENT_ID=$CLIENT_ID
GOOGLE_CLIENT_SECRET=$CLIENT_SECRET
EOF

echo ""
echo "✅ Created .env file successfully!"
echo ""
echo "==================================="
echo "Next Steps:"
echo "==================================="
echo ""
echo "1. TEST LOCALLY:"
echo "   make run"
echo ""
echo "2. ADD TO GITHUB SECRETS (for automated builds):"
echo "   Go to: https://github.com/mishamo/qr-reader/settings/secrets/actions"
echo "   Add these secrets:"
echo "   - GOOGLE_CLIENT_ID = $CLIENT_ID"
echo "   - GOOGLE_CLIENT_SECRET = [your secret]"
echo ""
echo "3. BUILD APK WITH CREDENTIALS:"
echo "   git push origin master"
echo "   (GitHub Actions will build with embedded credentials)"
echo ""
echo "==================================="