# Create Firestore Index - REQUIRED!

## The Problem

The polling system that shows popups to admins needs a Firestore index, but it doesn't exist yet. That's why you see this error:

```
🔄 ❌ Error checking notifications: [cloud_firestore/failed-precondition] The query requires an index
```

## The Solution

You need to create the index in Firebase Console. It takes 2 minutes.

### Step 1: Click the Link

The error message includes a direct link to create the index. Click this URL:

```
https://console.firebase.google.com/v1/r/project/ipila-9016a/firestore/indexes?create_composite=ClFwcm9qZWN0cy9pcGlsYS05MDE2YS9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvbm90aWZpY2F0aW9ucy9pbmRleGVzL18QARoKCgZ1c2VySWQQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC
```

OR manually go to:
1. [Firebase Console](https://console.firebase.google.com/)
2. Select project: **ipila-9016a**
3. Click **Firestore Database** in left menu
4. Click **Indexes** tab
5. Click **Create Index**

### Step 2: Configure the Index

If manually creating, use these settings:

- **Collection ID**: `notifications`
- **Fields to index**:
  1. Field: `userId`, Order: `Ascending`
  2. Field: `createdAt`, Order: `Descending`
- **Query scope**: Collection

### Step 3: Click "Create"

Firebase will start building the index. You'll see:

```
⏳ Building index...
```

This usually takes **1-5 minutes** depending on how many notifications exist.

### Step 4: Wait for Completion

When done, the status will change to:

```
✅ Enabled
```

### Step 5: Test Again

1. Reload your admin browser
2. You should no longer see the index error
3. Submit a report from user browser
4. Within 3 seconds, popup should appear in admin browser!

---

## Alternative: Deploy Index File

I've created `firestore.indexes.json` in the project root. To deploy it:

```bash
cd ipila
firebase deploy --only firestore:indexes
```

This will create the index automatically (still takes 1-5 min to build).

---

## Why This Happens

The polling system queries:
```dart
.where('userId', isEqualTo: adminId)
.orderBy('createdAt', descending: true)
```

Firestore requires a composite index for queries that use both `.where()` and `.orderBy()` on different fields.

---

## After Index is Created

You should see in admin console:
```
🔄 Found X notifications (checking for new ones)
🔄 New notification found:
🔄   Title: New Report: [category]
🔄   📢 Triggering popup via GlobalNotificationManager
📢 GlobalNotificationManager.showNotification called
📢 ✅ Showing notification popup now
🎯 ✅ Popup shown successfully
```

And the popup will appear in the admin browser! 🎉
