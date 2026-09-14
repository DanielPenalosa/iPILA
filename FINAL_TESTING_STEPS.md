# Final Testing Steps for Notification System

## 🎯 What Was Fixed

1. **Notification Listener** - Now processes last 5 notifications and tracks IDs to avoid duplicates
2. **Context Handling** - Multiple fallbacks to ensure popup can show
3. **Debug Logging** - Extensive logging to see exactly what's happening
4. **Sound File** - Added notification.mp3 to repository

## 📋 Testing Steps

### Step 1: Clean Build & Restart
```bash
# In terminal, run these commands:
cd C:\Users\ASUS\Desktop\iPILA\ipila
flutter clean
flutter pub get
flutter run -d chrome
```

**Why?** New assets (sound file) need a clean build to be recognized.

### Step 2: Open Browser Console
1. When app loads, press **F12** to open DevTools
2. Go to **Console** tab
3. Keep this open to see debug logs

### Step 3: Login as Admin
1. Login with admin credentials
2. **Watch console** - you should see:
```
🔔 ===== STARTING NOTIFICATION LISTENER =====
🔔 User ID: [your-admin-id]
🔔 Started at: [timestamp]
```

If you don't see this, the listener isn't starting.

### Step 4: Test with Test Button
1. Go to **Reports** screen
2. Click the **orange "Show Test Popup" button**
3. **Watch console** - you should see:
```
🧪 TEST BUTTON CLICKED
🎯 NotificationPopup.show called: Test New Report
🎯 Starting sound loop...
🔊 ========== STARTING SOUND LOOP ==========
🔊 Audio file path: sounds/notification.mp3
🔊 Platform: Web
🔊 Release mode set to: LOOP
🔊 Volume set to: 1.0 (100%)
🔊 Source created: ...
🔊 Calling player.play()...
🔊 ✅ SOUND LOOP STARTED SUCCESSFULLY!
```

4. **Popup should appear in center** with animation
5. **Sound should play in loop** (if not, see troubleshooting below)
6. Click **"Dismiss"** to stop sound

### Step 5: Test Real Notification
1. Keep admin logged in (don't close this window)
2. Open **new incognito window** or **different browser**
3. Go to same app URL
4. Login as **regular user**
5. **Submit a report**
6. **Watch the admin window** - you should see:
```
🔔 ----- Notification snapshot received -----
🔔 Number of notifications: 1
🔔 Processing notification:
🔔   Title: New Report: [category]
🔔   Type: new_report
🔔   🆕 NEW NOTIFICATION DETECTED!
🔔   Will show popup: true
🔔   📢 Triggering popup...
🔔   🎯 Post-frame callback executing...
🔔   ✅ Using navigator context
🔔   🚀 Showing popup NOW!
🎯 NotificationPopup.show called: New Report: [category]
🔊 ========== STARTING SOUND LOOP ==========
🔊 ✅ SOUND LOOP STARTED SUCCESSFULLY!
```

7. **Popup should appear** in admin window
8. **Sound should loop**
9. Click to dismiss

## 🔧 Troubleshooting

### If Listener Doesn't Start
**Console shows nothing when you login**

- Check: Is user logged in? Look for auth state in console
- Try: Refresh the page
- Check: `lib/main.dart` - listener should start in builder

### If Popup Shows But No Sound
**Console shows sound error**

Check the error message:

#### Error: "404" or "not found"
```
🔊 💡 The sound file was not found!
```
**Solution:**
- File must be at: `ipila/assets/sounds/notification.mp3`
- Run: `flutter clean && flutter pub get`
- Restart app

#### Error: "format" or "codec"
```
🔊 💡 The sound file format might not be supported!
```
**Solution:**
- Download different MP3 file
- Try: https://notificationsounds.com/
- Convert with different encoder

#### Error: "autoplay" or "permission"
```
🔊 💡 Browser might be blocking audio autoplay!
```
**Solution:**
- Browser blocks autoplay until user interacts
- Click somewhere on page first
- Check browser settings for audio permissions
- Try in different browser (Chrome works best)

### If Popup Doesn't Show
**Console shows listener working but no popup**

Look for these lines:
```
🔔   ❌ ERROR: No valid context available!
🔔   ❌ Context mounted: false
```

**Solution:**
- This means Flutter widget tree isn't ready
- Try refreshing page
- Check if you're on correct route (not login screen)

### If Nothing Works
**No console logs at all**

1. **Clear browser cache** (Ctrl+Shift+Delete)
2. **Hard refresh** (Ctrl+F5)
3. **Run:** `flutter clean && flutter pub get && flutter run -d chrome`
4. Check: Are you looking at correct browser window/tab?

## ✅ Success Checklist

- [ ] Console shows listener starting when I login
- [ ] Test button shows popup
- [ ] Test button plays looping sound
- [ ] Real report triggers popup in admin window
- [ ] Real report plays sound  
- [ ] Clicking "Dismiss" stops sound
- [ ] Clicking "View Report" navigates correctly

## 🗑️ After Everything Works

Remove the test button:

Edit: `lib/features/admin/screens/admin_reports_screen.dart`

Delete this section (around line 755):
```dart
// TEST BUTTON - REMOVE AFTER TESTING
Container(
  color: Colors.amber[100],
  ...
),
```

## 📝 Debug Log Reference

| Emoji | Meaning |
|-------|---------|
| 🔔 | Notification listener events |
| 🎯 | Popup show/dismiss events |
| 🔊 | Sound play/stop events |
| 🧪 | Test button clicked |
| ✅ | Success |
| ❌ | Error |
| 🆕 | New notification detected |
| 📢 | Triggering popup |
| 💡 | Helpful hint |

## 🎉 Expected Final Result

When a user submits a report:
1. **Admin sees popup** appear in center immediately
2. **Sound plays in continuous loop** (ding ding ding...)
3. **Popup has pulsing icon** animation
4. **Clicking View Report** opens report + stops sound
5. **Clicking Dismiss** just stops sound
6. **All sections/routes** receive notification (doesn't matter where admin is)

Same for barangay/department when assigned!
