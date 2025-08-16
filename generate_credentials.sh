#!/bin/bash

# Script to generate credentials.go from .env file for local development

if [ ! -f .env ]; then
    echo "❌ .env file not found. Run ./setup_credentials.sh first!"
    exit 1
fi

# Source the .env file
source .env

# Create credentials.go
cat > internal/auth/credentials.go << EOF
package auth

// THIS FILE IS AUTO-GENERATED - DO NOT EDIT
// Generated from .env for local development

func init() {
    buildTimeClientID = "$GOOGLE_CLIENT_ID"
    buildTimeClientSecret = "$GOOGLE_CLIENT_SECRET"
}
EOF

echo "✅ Generated internal/auth/credentials.go from .env"
echo "You can now run: make build-android"