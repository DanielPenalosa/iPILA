# How to Deploy Notification Fix

## What Was Fixed

1. **Removed test buttons** from admin reports screen
2. **Fixed notification polling** to look back 5 minutes instead of starting from "now"
3. **Improved query performance** with descending order and higher limit

## IMPORTANT: You Must Rebuild the App

The changes we made are in the Dart code, which gets compiled to JavaScript for web. The browser is still running the OLD compiled version. You need to:

### Step 1: Stop the Current App
Close the browser tab or stop the Flutter web server if running.

### Step 2: Clean Build Cache
```bash
cd ipila
flutter clean
```

### Step 3: Rebuild the App
```bash
flutter build web
```

### Step 4: Redeploy
If you're using Firebase Hosting:
```bash
firebase deploy --only hosting
```

Or if running locally:
```bash
flutter run -d chrome
```

### Step 5: Hard Refresh Browser
After redeploying, open the admin panel and do a hard refresh:
- **Windows**: `Ctrl + Shift + R` or `Ctrl + F5`
- **Mac**: `Cmd + Shift + R`

This clears the cached JavaScript files.

## How to Test

1. Open admin panel in one browser
2. Open user panel in another browser (or incognito)
3. Submit a concern as a user
4. Within 3 seconds, admin should see popup with sound

## Troubleshooting

### Still Not Working?
Check browser console logs (F12):
- Look for `🔄 Last check time initialized to:` 
- It should show "5 min ago" NOT the current time
- If it shows current time, the old code is still cached

### Clear Everything:
1. Clear browser cache completely
2. Close all iPILA tabs
3. Run `flutter clean` again
4. Rebuild with `flutter build web --release`
5. Redeploy

## Technical Details

The issue was that when admins logged in, `_lastCheckTime` was set to `DateTime.now()`, so any notifications created before that exact moment would be skipped as "too old". By setting it to 5 minutes ago, we catch recent notifications that were created while the admin was logging in or just before.

The logs you showed had notifications at 20:43, 20:35, etc. but polling started at 20:49 with `_lastCheckTime = 20:49`, so they were all skipped. Now it will start at 20:44 (5 min before 20:49) and catch those notifications.
