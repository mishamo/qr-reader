#!/bin/bash

# Generate a release keystore for the QR Scanner app
# This only needs to be run once

echo "Generating release keystore for QR Scanner..."
echo "Please enter the following information:"

keytool -genkey -v \
  -keystore qr-scanner-release.keystore \
  -alias qr-scanner \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass "${KEYSTORE_PASSWORD:-changeme}" \
  -keypass "${KEYSTORE_PASSWORD:-changeme}" \
  -dname "CN=QR Scanner, OU=Development, O=Mishamo, L=Unknown, ST=Unknown, C=US"

echo ""
echo "Keystore generated: qr-scanner-release.keystore"
echo ""
echo "Getting SHA-1 fingerprint for Google Cloud Console..."
keytool -list -v \
  -keystore qr-scanner-release.keystore \
  -alias qr-scanner \
  -storepass "${KEYSTORE_PASSWORD:-changeme}" | grep SHA1

echo ""
echo "IMPORTANT: "
echo "1. Keep qr-scanner-release.keystore file safe and backed up!"
echo "2. Add the SHA-1 fingerprint above to Google Cloud Console"
echo "3. Upload keystore to GitHub Secrets for CI/CD"