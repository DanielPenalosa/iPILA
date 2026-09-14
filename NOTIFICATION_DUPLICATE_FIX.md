# Notification Duplicate Bug - FIXED ✅

## The Problem

After acknowledging a notification and logging out, the same notification would appear again when logging back in. This happened because:

1. Notifications were **never marked as read** in Firestore
2. The `_processedNotificationIds` set was **stored in memory only**
3. When logging out, the memory was cleared
4. On login, the system would fetch the same old notifications again

## The Solution

### 1. Query Only UNREAD Notifications ✅

**Before**:
```dart
.where('userId', isEqualTo: _userId)
.orderBy('createdAt', descending: true)
```

**After**:
```dart
.where('userId', isEqualTo: _userId)
.where('isRead', isEqualTo: false)  // Only unread!
.orderBy('createdAt', descending: true)
```

### 2. Mark as Read When User Interacts ✅

Notifications are now marked as read (`isRead: true`) in Firestore when:
- ✅ User clicks "Acknowledge"
- ✅ User clicks "View Report"
- ✅ User dismisses by clicking outside the dialog

### 3. Pass Notification ID Through All Layers ✅

**Flow**:
```
NotificationProvider 
  → GlobalNotificationManager 
    → SimpleNotificationPopup 
      → Mark as read in Firestore
```

Each layer now passes the `notificationId` so we can update it.

### 4. Added New Firestore Index ✅

**New index for**:
- `userId` (ascending)
- `isRead` (ascending)
- `createdAt` (descending)

This allows efficient querying of unread notifications sorted by newest first.

## Files Changed

### 1. `lib/core/providers/notification_provider.dart`
- Added `.where('isRead', isEqualTo: false)` to query
- Pass `notificationId` to GlobalNotificationManager
- Better logging for unread notifications

### 2. `lib/core/services/global_notification_manager.dart`
- Added `notificationId` parameter
- Pass it through to SimpleNotificationPopup
- Updated _PendingNotification class

### 3. `lib/core/widgets/simple_notification_popup.dart`
- Added `notificationId` parameter
- Created `_markNotificationAsRead()` method
- Mark as read in all dismiss scenarios:
  - Acknowledge button clicked
  - View Report button clicked
  - Dialog dismissed by barrier tap

### 4. `firestore.indexes.json`
- Added new composite index:
  - userId + isRead + createdAt (DESC)

## How It Works Now

### User Submits Report
1. Notification created with `isRead: false`
2. Admin polling detects unread notification
3. Popup appears with sound

### Admin Acknowledges
1. User clicks "Acknowledge" (or View Report, or dismisses)
2. Firestore updated: `isRead: true`
3. Popup closes, sound stops

### Admin Logs Out & Back In
1. Query only fetches `isRead: false` notifications
2. The acknowledged notification is **not returned**
3. No duplicate popup! ✅

## Testing

### Test 1: Basic Flow
1. Submit a concern as user
2. Admin sees popup
3. Click "Acknowledge"
4. Logout
5. Login again
6. ✅ Popup should NOT appear

### Test 2: View Report Flow
1. Submit a concern as user
2. Admin sees popup
3. Click "View Report"
4. Logout
5. Login again
6. ✅ Popup should NOT appear

### Test 3: Dismiss by Click Outside
1. Submit a concern as user
2. Admin sees popup
3. Click outside the popup (barrier)
4. Logout
5. Login again
6. ✅ Popup should NOT appear

## Database Impact

### Before (Old Notifications)
Existing notifications might not have `isRead` field. They will be:
- Treated as unread (because `isRead` is not `false`)
- Shown once more after this update
- Then marked as read when acknowledged

### After (New Notifications)
All new notifications will have:
```firestore
{
  id: "...",
  userId: "...",
  title: "...",
  body: "...",
  type: "new_report",
  isRead: false,  ← This field
  createdAt: Timestamp
}
```

## Deploy Instructions

**Index is already deployed!** ✅

Just rebuild and redeploy the app:
```bash
cd ipila
flutter clean
flutter build web
firebase deploy --only hosting
```

Hard refresh: **Ctrl + Shift + R**

## Expected Behavior

✅ Notifications appear once
✅ After acknowledging, they never appear again
✅ Even after logout/login
✅ Multiple admins can each see and acknowledge independently
✅ Each admin has their own `isRead` status (different userId)

---

**Bug fixed! No more duplicate notifications!** 🎉
