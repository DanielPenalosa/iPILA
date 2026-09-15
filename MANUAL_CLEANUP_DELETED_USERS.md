# Manual Cleanup of Deleted Users

## Problem
You deleted department/barangay accounts using the old code, which only marked them as `approvalStatus: 'deleted'` instead of completely removing them. They still appear in the UI.

## Solution: Clean Up via Firebase Console

### Step 1: Open Firestore Console
1. Go to https://console.firebase.google.com
2. Select your project: **ipila-9016a**
3. Click **Firestore Database** in the left menu
4. Click **users** collection

### Step 2: Find Deleted Users
Look for documents with these fields:
- `approvalStatus: "deleted"` 
- `isDeleted: true`

### Step 3: Delete Them Manually
1. Click on each document that has `approvalStatus: "deleted"`
2. Click the **Delete document** button (trash icon)
3. Confirm deletion

The specific users from your screenshot:
- **Engineering Office** (engroffice@pila.gov.ph)
- **Environment & Natural Resources** (menropila@gmail.com)

### Alternative: Deploy the New Code First

If you haven't deployed yet, the new code will handle this automatically:

1. **Deploy the updated code:**
   ```bash
   cd ipila
   flutter clean
   flutter build web
   firebase deploy --only hosting
   ```

2. **Clear browser cache:**
   - Press `Ctrl + Shift + R` (hard refresh)
   - Or clear all browser data for the site

3. **Delete them again in the UI:**
   - The new code will completely remove them from Firestore
   - They won't reappear after logout/login

## Why This Happened

The old `deleteUser()` method used:
```dart
// OLD CODE (marked as deleted)
await _db.collection('users').doc(uid).update({
  'isDeleted': true,
  'approvalStatus': 'deleted',
});
```

The new `deleteUser()` method uses:
```dart
// NEW CODE (completely removes)
await _db.collection('users').doc(uid).delete();
```

## Verification

After cleanup, refresh the page and check:
- ✅ Department Accounts section should only show active accounts
- ✅ Barangay Accounts section should only show active accounts
- ✅ Deleted accounts should not reappear after logout/login

---

**Quick Fix**: Just delete those 2 documents manually from Firestore Console now, then deploy the new code to prevent this issue in the future.
