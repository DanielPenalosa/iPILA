# Logo Setup Instructions

## Overview
This guide will help you set up the iPila logo across your Flutter web application.

## Step 1: Prepare Your Logo File

You have the logo at: `C:\Users\penal\Downloads\logo-pila.png`

## Step 2: Copy Logo to Assets Folder

Manually copy the logo file:
- **Source**: `C:\Users\penal\Downloads\logo-pila.png`
- **Destination**: `ipila\assets\images\logo.png`

## Step 3: Generate Web Icons

You need to create different sizes of your logo for web icons. You can use an online tool or image editor to resize your logo:

### Required Icon Sizes:
1. **favicon.png** - 32x32 pixels
2. **Icon-192.png** - 192x192 pixels
3. **Icon-512.png** - 512x512 pixels
4. **Icon-maskable-192.png** - 192x192 pixels (with safe zone padding)
5. **Icon-maskable-512.png** - 512x512 pixels (with safe zone padding)

### Online Tools You Can Use:
- https://favicon.io/favicon-converter/
- https://realfavicongenerator.net/
- https://www.websiteplanet.com/webtools/favicon-generator/

### Manual Steps:
1. Upload `logo-pila.png` to one of the tools above
2. Download the generated icon pack
3. Replace the following files in your project:
   - `ipila\web\favicon.png`
   - `ipila\web\icons\Icon-192.png`
   - `ipila\web\icons\Icon-512.png`
   - `ipila\web\icons\Icon-maskable-192.png`
   - `ipila\web\icons\Icon-maskable-512.png`

## Step 4: Verify Configuration

The following files are already configured correctly:
- ✅ `pubspec.yaml` - includes assets/images/logo.png
- ✅ `web/manifest.json` - references the icon files
- ✅ `web/index.html` - links to favicon

## Step 5: Test Your Changes

After copying all files:

1. Run `flutter clean` in the ipila directory
2. Run `flutter pub get`
3. Run `flutter run -d chrome` to test in browser
4. Check that:
   - Logo appears in the app
   - Favicon shows in browser tab
   - PWA icons are correct when installing

## Notes

- **Maskable icons** should have important content in the center "safe zone" (80% of the image)
- The outer 20% may be cropped on some devices
- Keep your logo centered with padding for maskable versions

## Quick Command Reference

```cmd
cd ipila
flutter clean
flutter pub get
flutter run -d chrome
```
