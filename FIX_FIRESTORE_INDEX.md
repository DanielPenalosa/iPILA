# Fix Firestore Index Error

## The Problem
The notification query is failing with this error:
```
[cloud_firestore/failed-precondition] The query requires an index.
```

This is because we changed the query to use `orderBy('createdAt', descending: true)` but Firestore doesn't have the right index yet.

## Solution: Create the Index in Firebase Console

### Option 1: Use the Auto-Generated Link (FASTEST)
1. Click this link from your error message (or copy from browser console):
   ```
   https://console.firebase.google.com/v1/r/project/ipila-9016a/firestore/indexes?create_composite=...
   ```
2. Click "Create Index"
3. Wait 2-5 minutes for index to build
4. Refresh your app

### Option 2: Manual Creation
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **ipila-9016a**
3. Go to **Firestore Database** > **Indexes** tab
4. Click **Create Index**
5. Set:
   - Collection ID: `notifications`
   - Fields to index:
     - Field: `userId`, Order: `Ascending`
     - Field: `createdAt`, Order: `Descending`
   - Query scope: `Collection`
6. Click **Create**
7. Wait for index to build (2-5 minutes)

## How to Verify It's Working

Once the index is built, refresh your admin page and check the console:
- ✅ Should see: `🔄 Query completed - found X total notifications`
- ❌ No more: `🔄 ❌ Error checking notifications`

## Updated Index Configuration

I've already updated `firestore.indexes.json` to include both indexes:
- `userId ASC + createdAt ASC` (for other queries)
- `userId ASC + createdAt DESC` (for notification polling)

## After Index is Created

Once you see the query working in the console logs, test the full flow:
1. Open admin panel (you)
2. Open user panel in another browser (or incognito)
3. Submit a new concern as user
4. Within 3 seconds → admin should see popup with sound ✅
