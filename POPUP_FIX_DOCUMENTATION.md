# Notification Popup Fix - Admin Screens

## Problem
When a user filed a concern (report), the notification popup was not appearing on admin screens. The test popup worked, but the real notifications triggered by Firestore were not displaying.

## Root Cause
The `NotificationListenerService` was trying to use the BuildContext passed during initialization, but this context could become invalid when navigating between different admin screens. The issue was in the context validation logic that tried to find a valid context but couldn't reliably access the root overlay across all screens.

## Solution

### Changes Made

1. **notification_listener_service.dart**
   - Added a static `GlobalKey<NavigatorState>` field to store the root navigator key
   - Added `setNavigatorKey()` method to set the global navigator key
   - Modified the popup trigger logic to use the global navigator key's context first, falling back to the provided context if needed
   - This ensures the popup can always access a valid context that's attached to the root overlay

2. **app_router.dart**
   - Exported the existing `_rootNavigatorKey` via a getter `rootNavigatorKey`
   - This allows other services to access the root navigator key

3. **main.dart**
   - Added call to `NotificationListenerService.setNavigatorKey(rootNavigatorKey)` during initialization
   - This connects the notification service to the root navigator

## How It Works Now

1. When the app starts, the root navigator key is registered with the notification service
2. When a new report is submitted:
   - Firestore creates a notification document for all admins
   - The `NotificationListenerService` detects the new notification
   - It uses the global navigator key to get a context that's always valid and attached to the root overlay
   - The popup is shown using `Overlay.of(context, rootOverlay: true)` which displays it above all admin screens

## Testing

To test the fix:
1. Log in as a regular user
2. Submit a new report
3. Log in as admin in another browser/device (or use incognito mode)
4. The popup should appear on any admin screen (Dashboard, Reports, Users, Analytics, etc.)

The test button in `admin_reports_screen.dart` can also be used to verify the popup works correctly.

## Technical Details

### Why rootOverlay: true?
Using `rootOverlay: true` ensures the popup is displayed in the root overlay, above all navigation shells and screen content. This makes it visible regardless of which admin screen is currently active.

### Why Global Navigator Key?
The global navigator key provides a stable reference to the root navigator's context, which remains valid throughout the app lifecycle and across all screens. This is more reliable than trying to use screen-specific contexts that may be disposed during navigation.

## Files Modified
- `ipila/lib/data/services/notification_listener_service.dart`
- `ipila/lib/core/utils/app_router.dart`
- `ipila/lib/main.dart`
