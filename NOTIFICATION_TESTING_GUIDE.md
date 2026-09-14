# Notification System Testing Guide

## What Was Implemented

A complete popup notification system with looping sound that alerts users in real-time when important events occur.

## How It Works

1. **User submits a report** → Admin sees popup + looping sound 🔔🔔🔔
2. **Admin assigns to barangay** → Barangay user sees popup + looping sound 🔔🔔🔔
3. **Admin assigns to department** → Department user sees popup + looping sound 🔔🔔🔔

## Testing Steps

### Setup
1. Make sure you have the app running
2. Check browser console for debug logs (press F12)
3. Replace `assets/sounds/notification.mp3` with a longer sound (5-10 seconds) if needed

### Test 1: Admin Receives New Report
1. **Login as Admin** in one browser window
2. **Check console** - you should see: `🔔 Starting notification listener for user: [admin-id]`
3. **Open another browser/incognito** and login as a regular user
4. **Submit a new report** from the user account
5. **Watch the admin window** - you should see:
   - `🔔 NEW NOTIFICATION DETECTED! Showing popup...`
   - `🎯 NotificationPopup.show called: New Report: [category]`
   - `🔊 Starting sound loop...`
   - **Center popup appears** with pulsing icon
   - **Sound plays in loop** continuously
6. **Click "View Report"** or **"Dismiss"** → popup closes, sound stops

### Test 2: Barangay Receives Assignment
1. **Login as Barangay user** in one browser window
2. **Login as Admin** in another window
3. **From admin**: Go to Reports and assign a report to a barangay
4. **Watch the barangay window** - popup should appear with looping sound
5. Click to dismiss

### Test 3: Department Receives Assignment
1. **Login as Department user** in one browser window
2. **Login as Admin** in another window
3. **From admin**: Assign a report to that department
4. **Watch the department window** - popup should appear with looping sound
5. Click to dismiss

## Debug Console Logs

Watch for these logs in the browser console:

### When listener starts:
```
🔔 Starting notification listener for user: xyz123
```

### When notification arrives:
```
🔔 Latest notification: New Report: Traffic (type: new_report) at 2026-09-14...
🔔 NEW NOTIFICATION DETECTED! Showing popup...
🎯 NotificationPopup.show called: New Report: Traffic
🎯 Starting sound loop...
🔊 Starting sound loop...
🔊 Sound loop started successfully
🎯 Inserting overlay...
🎯 Popup shown successfully
```

### When dismissed:
```
🎯 NotificationPopup.dismiss called
🔊 Stopping sound loop...
🔊 Sound loop stopped
🎯 Popup dismissed
```

## Troubleshooting

### No popup appears
- Check console for error messages
- Look for `🔔 Context not available for popup`
- Make sure user is logged in
- Try refreshing the page

### No sound plays
- Check if `assets/sounds/notification.mp3` exists
- Look for `🔊 Sound loop error` in console
- Check browser sound permissions
- Try a different audio file

### Popup appears but old notifications trigger it
- This is expected on first login
- The listener only shows popups for notifications AFTER you logged in
- Check the log: `🔔 Old notification, skipping popup`

### Sound won't stop
- Check if dismiss was called: `🎯 NotificationPopup.dismiss called`
- Look for `🔊 Sound loop stopped` in console
- Refresh the page as a workaround

## Sound File Recommendations

The current sound might be too short. Replace it with:

1. Visit: https://pixabay.com/sound-effects/search/notification%20alarm/
2. Download a 5-10 second notification sound
3. Convert to MP3 if needed
4. Replace `ipila/assets/sounds/notification.mp3`
5. Restart the app

Good search terms:
- "notification alarm"
- "bell ring long"
- "phone ringtone"
- "alert sound"

## Expected Behavior

✅ Popup appears in center of screen
✅ Icon pulses with animation
✅ Sound loops continuously
✅ Clicking "View Report" navigates and stops sound
✅ Clicking "Dismiss" just stops sound
✅ Only shows for new notifications (not old ones)
✅ Works for Admin, Barangay, and Department users

## Notes

- The system uses Firestore real-time listeners
- Notifications are checked every time the database updates
- Sound will loop until user interaction
- Multiple popups are prevented (only one at a time)
- Old notifications from before login are ignored
