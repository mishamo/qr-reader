# ✨ New QR Code App Icon!

## What's New

Your QR Scanner app now has a custom QR code-style icon instead of the default Flutter logo!

### Icon Design Features:
- **QR Code Pattern**: Classic QR code appearance with position detection squares
- **Three Corner Squares**: Traditional QR code corner markers
- **Center Accent**: Blue pattern in the center for visual interest
- **Material Design Colors**: Uses Material Blue (#2196F3) for accent
- **Adaptive Icon**: Works with Android 8+ adaptive icon system

### Icon Files Created:
- `app_icon.png` - Main icon (1024x1024)
- `play_store_icon.png` - For Google Play Store (512x512)
- All Android density icons (mdpi to xxxhdpi)

### Visual Description:
```
┌─────────┐     ┌─────────┐
│ ■■■■■■■ │     │ ■■■■■■■ │
│ ■     ■ │     │ ■     ■ │
│ ■ ■■■ ■ │ ■ ■ │ ■ ■■■ ■ │
│ ■ ■■■ ■ │     │ ■ ■■■ ■ │
│ ■ ■■■ ■ │ QR  │ ■ ■■■ ■ │
│ ■     ■ │     │ ■     ■ │
│ ■■■■■■■ │     │ ■■■■■■■ │
└─────────┘     └─────────┘
     ■ ■ ■   ■ ■ ■ ■
        [Blue Center]
     ■ ■ ■   ■ ■ ■ ■
┌─────────┐     ┌───┐
│ ■■■■■■■ │     │■■■│
│ ■     ■ │ ■ ■ │■ ■│
│ ■ ■■■ ■ │     │■■■│
│ ■ ■■■ ■ │     └───┘
│ ■ ■■■ ■ │   Alignment
│ ■     ■ │    Pattern
│ ■■■■■■■ │
└─────────┘
```

## Testing the New Icon

### The icon is now included in your APK:
```bash
# Install the APK with new icon
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Where You'll See It:
1. **App Drawer** - Main app list
2. **Home Screen** - When added as shortcut
3. **Recent Apps** - Task switcher
4. **Settings** - App info page
5. **Play Store** - When published

## Technical Details

### Added to Project:
- `flutter_launcher_icons: ^0.14.4` package
- Icon configuration in `pubspec.yaml`
- Generated Android resources in `res/` folders

### Adaptive Icon Support:
- Foreground layer with QR pattern
- White background for consistency
- Works with Android's icon shapes (circle, square, squircle, teardrop)

## Next Build

The CI is building a new release with the custom icon:
- Check: https://github.com/mishamo/qr-reader/actions
- New releases will show the QR code icon

## Icon Customization

If you want to adjust the icon:
1. Modify `create_qr_icon.py` script
2. Run: `python3 create_qr_icon.py`
3. Run: `dart run flutter_launcher_icons`
4. Rebuild the app

The icon gives your app a professional, purpose-built appearance that immediately tells users this is a QR code scanning app! 🎯