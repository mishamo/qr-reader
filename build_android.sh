#!/bin/bash

echo "QR Scanner Android Build Script"
echo "================================"

# Check for Android SDK/NDK
if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_NDK_HOME" ]; then
    echo "❌ Android SDK/NDK not found!"
    echo ""
    echo "To build the Android APK, you need to:"
    echo ""
    echo "Option 1: Install Android Studio (Recommended)"
    echo "  1. Download Android Studio from: https://developer.android.com/studio"
    echo "  2. Open Android Studio and go to Tools > SDK Manager"
    echo "  3. Install Android SDK and NDK"
    echo "  4. Set environment variables:"
    echo "     export ANDROID_HOME=~/Library/Android/sdk"
    echo "     export ANDROID_NDK_HOME=\$ANDROID_HOME/ndk/[version]"
    echo "     export PATH=\$PATH:\$ANDROID_HOME/platform-tools"
    echo ""
    echo "Option 2: Install via Homebrew (macOS)"
    echo "  brew install --cask android-sdk"
    echo "  brew install --cask android-ndk"
    echo ""
    echo "After installation, run this script again."
    exit 1
fi

echo "✅ Android SDK/NDK found"
echo "  ANDROID_HOME: $ANDROID_HOME"
echo "  ANDROID_NDK_HOME: $ANDROID_NDK_HOME"
echo ""

# Build the APK
echo "Building APK..."
fyne package \
    --target android \
    --app-id com.mishamo.qrreader \
    --name "QR Scanner" \
    --icon Icon.png \
    --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "APK location: QR Scanner.apk"
    echo ""
    echo "To install on your Android device:"
    echo "  1. Enable 'Developer Options' and 'USB Debugging' on your device"
    echo "  2. Connect your device via USB"
    echo "  3. Run: adb install 'QR Scanner.apk'"
    echo ""
    echo "Or transfer the APK to your device and install manually."
else
    echo ""
    echo "❌ Build failed. Please check the error messages above."
fi