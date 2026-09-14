# Notification Popup Fix

## Problem
Automatic notification popups and sounds were not appearing for admins after users submitted concerns.

## Root Cause
The issue was in the `NotificationProvider` initialization logic:

1. When polling started, `_lastCheckTime` was initialized to `DateTime.now()`
2. Any notifications created before that exact moment (even seconds earlier) would be skipped as "too old"
3. Since notifications are created when users submit reports, but admins might log in slightly after, those notifications would be missed

## Solution Applied

### 1. Changed Initial Check Time Window
**File**: `ipila/lib/core/providers/notification_provider.dart`

Changed:
```dart
_lastCheckTime = DateTime.now();
```

To:
```dart
_lastCheckTime = DateTime.now().subtract(const Duration(minutes: 5));
```

This ensures that when an admin logs in, they'll see notifications from the last 5 minutes, catching any reports submitted just before they logged in.

### 2. Improved Query Performance
- Changed query to use descending order (newest first) to prioritize recent notifications
- Increased limit from 10 to 20 notifications to catch more recent activity
- Maintained compatibility with existing Firestore index (`userId` ASC + `createdAt` DESC)

## How It Works Now

1. **User submits a concern** → Notification created in Firestore with `type: 'new_report'`
2. **Admin has browser open** → NotificationProvider polls every 3 seconds
3. **New notification detected** → Triggers `GlobalNotificationManager.showNotification()`
4. **Popup appears** with sound and visual notification
5. **Admin can click** to view the report or dismiss

## Testing
To test the fix:
1. Open admin panel in browser
2. Open user interface in another browser/tab
3. Submit a concern as a user
4. Within 3 seconds, admin should see popup with sound

## Files Modified
- `ipila/lib/core/providers/notification_provider.dart`
  - Line 27: Changed `_lastCheckTime` initialization
  - Line 68: Changed query from ascending to descending order
  - Line 69: Increased limit from 10 to 20
