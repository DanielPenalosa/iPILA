# User Account Deletion Behavior

## What Happens When You Delete a User Account

When you delete a department or barangay account from the Admin > Users screen:

### ✅ What Gets Deleted
1. **Firestore User Document** - The user document is completely removed from the `users` collection
2. **System Access** - The user can no longer access the iPILA system
3. **Admin UI** - The account disappears from the Users list immediately

### ⚠️ What Remains
1. **Firebase Auth Account** - The authentication account remains in Firebase Auth
   - Cannot be deleted from client-side code (requires Firebase Admin SDK)
   - User cannot login anyway because Firestore document is deleted
   
2. **Associated Reports** - Any reports assigned to or created by this user remain in the database
   - Reports are not orphaned - they retain the user's name and department/barangay
   - Historical data is preserved for records

### 🔄 Single vs Bulk Deletion
- **Single Delete**: Click the delete button on individual user cards
- **Bulk Delete**: Select multiple users and use "Delete Selected" action

Both methods completely remove the Firestore user documents.

### 💡 Why This Approach?
- **Data Integrity**: Reports and historical records are preserved
- **Audit Trail**: Past actions by deleted users remain traceable
- **Safety**: Cannot accidentally delete Firebase Auth (would require Cloud Functions)
- **Clean UI**: Deleted accounts don't appear in any user lists

### 🛠️ Future Enhancement
To fully delete Firebase Auth accounts, you would need to:
1. Set up Firebase Cloud Functions
2. Implement Firebase Admin SDK
3. Create a callable function to delete auth accounts
4. Call this function when deleting users

Current implementation is safe and effective for most use cases.

---

**Last Updated**: January 2026  
**Related Files**:
- `lib/data/services/user_management_service.dart`
- `lib/features/admin/screens/admin_users_screen.dart`
