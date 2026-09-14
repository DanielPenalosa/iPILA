# Quick Test Checklist for Notification Popup

## 🚀 Quick Test Steps

### 1. Pull & Restart
```bash
git pull
flutter clean
flutter pub get  
flutter run -d chrome
```

### 2. Login as Admin
- Open browser console (F12)
- Login to admin account
- Look for:
```
🔔 Auth changed - User: [admin-id]
🔔 Starting listener with global context
🔔 ===== STARTING NOTIFICATION LISTENER =====
```

### 3. Test on Different Admin Screens

**Test A: From Dashboard**
1. Stay on admin dashboard
2. In another browser: submit a report as user
3. Watch admin console for logs
4. ✅ Popup should appear on dashboard

**Test B: From Reports Screen**
1. Go to admin reports screen
2. Submit another report from user browser
3. ✅ Popup should appear on reports screen

**Test C: From Analytics Screen**
1. Go to admin analytics
2. Submit another report
3. ✅ Popup should appear on analytics

**Test D: From Users Screen**
1. Go to admin users screen
2. Submit another report
3. ✅ Popup should appear on users screen

### 4. Check Console Logs

When report is submitted, you should see:
```
🔔 ----- Notification snapshot received -----
🔔 Number of notifications: X
🔔 Processing notification:
🔔   Title: New Report: [category]
🔔   Type: new_report
🔔   🆕 NEW NOTIFICATION DETECTED!
🔔   Will show popup: true
🔔   📢 Triggering popup...
🔔   🎯 Post-frame callback executing...
🔔   ✅ Using global root context
🔔   🚀 Showing popup NOW!
🔔   ✅✅✅ Popup.show() called successfully!
🎯 NotificationPopup.show called: ...
🔊 ========== STARTING SOUND LOOP ==========
```

## ❌ If Popup Still Doesn't Show

### Check These Logs:

**If you see:**
```
🔔 ❌ ERROR: No valid context available!
```
→ Context issue - restart app

**If you see:**
```
🔔 ⚠️ Could not get global root context
🔔 ❌ Using navigator context
```
→ This is OK, it's a fallback

**If you see:**
```
🔔 ❌❌❌ Error showing popup: [error]
```
→ Share the full error message

**If you DON'T see notification detected at all:**
```
(No "NEW NOTIFICATION DETECTED" message)
```
→ Listener isn't receiving Firestore updates
→ Check: Is notification being created in Firestore?
→ Check: Firebase rules allow reading notifications?

## 🔍 Manual Firestore Check

1. Go to Firebase Console
2. Open Firestore Database
3. Find `notifications` collection
4. After submitting report, check if new notification appears
5. Check these fields:
   - `userId`: Should match admin's user ID
   - `type`: Should be `'new_report'`
   - `createdAt`: Should be recent timestamp
   - `title`: Should say "New Report: [category]"

If notification IS in Firestore but popup doesn't show:
- It's a listener/context issue
- Share console logs

If notification is NOT in Firestore:
- Issue is in report submission
- Check `report_service.dart` → `_notifyAdmins()`

## ✅ Success Criteria

- [ ] Listener starts when admin logs in
- [ ] Console shows "STARTING NOTIFICATION LISTENER"
- [ ] Submit report from user account
- [ ] Console shows "NEW NOTIFICATION DETECTED"
- [ ] Console shows "Popup.show() called successfully"
- [ ] Popup appears in center of screen
- [ ] Sound plays in loop
- [ ] Works on ALL admin screens (Dashboard, Reports, Analytics, Users, etc.)
- [ ] Click "Dismiss" stops sound
- [ ] Click "View Report" navigates correctly

## 💡 Pro Tips

1. **Keep console open** - it tells you everything
2. **Test on different screens** - popup should show everywhere
3. **Don't reload during test** - listener needs to stay active
4. **Check timestamps** - old notifications won't trigger popup
5. **One report at a time** - wait for popup before submitting next

## 🆘 Still Not Working?

Share these from console:
1. The "===== STARTING NOTIFICATION LISTENER =====" block
2. The "NEW NOTIFICATION DETECTED" block (or lack of it)
3. Any ❌ ERROR messages
4. Screenshot of Firestore notifications collection
