#!/bin/bash

# Script to debug Google Sign-In issues on Android device

echo "=== Google Sign-In Debug Helper ==="
echo "This script will help capture logs from your Android device"
echo ""

# Check if adb is available
if ! command -v adb &> /dev/null; then
    echo "Error: adb not found. Please install Android SDK."
    exit 1
fi

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "Error: No Android device connected."
    echo "Please connect your device and enable USB debugging."
    exit 1
fi

echo "Device connected. Starting log capture..."
echo ""
echo "Instructions:"
echo "1. Clear previous app data: Settings → Apps → QR Scanner → Storage → Clear Data"
echo "2. Install the debug APK: adb install build/app/outputs/flutter-apk/app-debug.apk"
echo "3. Open the app and try to sign in"
echo "4. The debug console will show in the app"
echo "5. Additionally, system logs will appear below"
echo ""
echo "Press Ctrl+C to stop capturing logs"
echo ""
echo "=== CAPTURING LOGS ==="

# Clear previous logs
adb logcat -c

# Capture logs related to Google Sign-In and our app
adb logcat -v time \
    | grep -E "GoogleSignIn|GmsAuth|Auth|qr_scanner|flutter|GoogleAuth|OAuth|SignIn" \
    | grep -v "chatty" \
    | while read line; do
        # Color code the output
        if echo "$line" | grep -q "ERROR\|E/"; then
            echo -e "\033[31m$line\033[0m"  # Red for errors
        elif echo "$line" | grep -q "WARNING\|W/"; then
            echo -e "\033[33m$line\033[0m"  # Yellow for warnings
        elif echo "$line" | grep -q "GoogleSignIn"; then
            echo -e "\033[36m$line\033[0m"  # Cyan for Google Sign-In
        elif echo "$line" | grep -q "qr_scanner"; then
            echo -e "\033[32m$line\033[0m"  # Green for our app
        else
            echo "$line"
        fi
    done