# Testing the Notification Popup - Quick Guide

## Test 1: Using the Test Button (Quick Test)

1. Log in as admin
2. Navigate to **Reports** screen
3. You'll see an orange test bar at the top with "TEST POPUP" label
4. Click the **"Show Test Popup"** button
5. ✅ Popup should appear with sound

**Expected Result:**
- Popup displays centered on screen
- Sound loops until dismissed
- Works on all admin screens

---

## Test 2: Real User Report (Full Integration Test)

### Setup (Use 2 browsers or incognito mode)

**Browser 1: Regular User**
1. Log in as a regular citizen user
2. Navigate to home screen
3. Click the + button to submit a new report

**Browser 2: Admin**
1. Log in as admin
2. Navigate to any admin screen (Dashboard, Reports, Users, Analytics, Map, Alerts, or Settings)

### Execute Test

**In Browser 1 (User):**
1. Fill out the report form:
   - Select a category (e.g., "Road Damage")
   - Add description
   - Select barangay
   - Upload photo (optional)
   - Capture location
2. Click **Submit Report**
3. Wait for confirmation

**In Browser 2 (Admin):**
1. Stay on any admin screen
2. Within a few seconds, you should see:
   - 🔔 A popup notification appears
   - 🔊 Sound plays and loops
   - Title: "New Report: [Category]"
   - Message shows who submitted and where

### Navigation Test

After seeing the popup:
1. Try navigating to different admin screens
2. Submit another report from Browser 1
3. ✅ Popup should appear regardless of which admin screen you're on

---

## Expected Behaviors

### ✅ Correct Behavior
- Popup appears on **all admin screens** (Dashboard, Reports, Users, Analytics, Map, Ordinances, Alerts, Settings)
- Sound loops until user dismisses or clicks "View Report"
- Popup is centered and modal (blocks interaction with screen beneath)
- Only one popup shows at a time (new ones replace old ones)
- "View Report" button navigates to the report detail screen
- "Dismiss" button closes the popup and stops sound

### ❌ Incorrect Behavior (What We Fixed)
- Popup not appearing at all
- Popup only working on some screens
- Console errors about invalid context
- Popup appearing behind other content

---

## Debug Mode

If the popup doesn't appear, check the console for debug messages:

Look for these log patterns:
```
🔔 ===== STARTING NOTIFICATION LISTENER =====
🔔 User ID: [admin-uid]
🔔 ----- Notification snapshot received -----
🔔   🆕 NEW NOTIFICATION DETECTED!
🔔   📢 Triggering popup...
🔔   🎯 Post-frame callback executing...
🔔   ✅ Using global navigator context
🔔   🚀 Showing popup NOW!
🎯 NotificationPopup.show called: [Title]
🎯 Starting sound loop...
🎯 Inserting overlay...
🎯 Popup shown successfully
```

If you see `❌ ERROR: No valid context available!`, the fix needs to be verified.

---

## Quick Troubleshooting

**Popup doesn't appear:**
1. Check console for errors
2. Verify admin is logged in
3. Ensure notification listener is running (check logs)
4. Try the test button first

**Sound doesn't play:**
1. Check browser sound permissions
2. Ensure notification.mp3 exists in assets/sounds/
3. Check volume settings

**Popup appears but is behind content:**
1. This shouldn't happen with `rootOverlay: true`
2. Check if multiple overlays are being created

---

## Clean Up

After testing:
1. The orange TEST POPUP bar can be removed from `admin_reports_screen.dart` (lines 755-779)
2. The test is located in the build method after `AdminPageHeader`
