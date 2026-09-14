# Official Barangay List - Updated ✅

## Changes Made

Updated the barangay list in `lib/core/constants/app_constants.dart` to match the **official Municipality of Pila, Laguna barangays**.

### Corrections

**Old (Incorrect):**
- San Pedro ❌
- Tibig ❌

**New (Official):**
- San Miguel ✅
- Tubuan ✅

## Complete Official List (17 Barangays)

1. Aplaya
2. Bagong Pook
3. Bukal
4. Bulilan Norte
5. Bulilan Sur
6. Concepcion
7. Labuin
8. Linga
9. Masico
10. Mojon
11. Pansol
12. Pinagbayanan
13. San Antonio
14. **San Miguel** (was incorrectly "San Pedro")
15. Santa Clara Norte
16. Santa Clara Sur
17. **Tubuan** (was incorrectly "Tibig")

## Impact

This update affects:
- ✅ Report submission dropdown (users can now select correct barangays)
- ✅ Barangay user accounts (admin can assign to correct barangays)
- ✅ Filtering and analytics (proper barangay names in reports)
- ✅ Maps and location displays

## Existing Data

**Reports with old barangay names** ("San Pedro" or "Tibig"):
- Will remain in the database with their old values
- Can still be viewed and managed
- Consider running a data migration script to update them if needed

**New reports** will use the correct barangay names.

## Deploy

```bash
cd ipila
flutter clean
flutter build web
firebase deploy --only hosting
```

Hard refresh: **Ctrl + Shift + R**

## Data Migration (Optional)

If you want to update existing reports with old barangay names, you can run a Firestore query:

```javascript
// Update "San Pedro" to "San Miguel"
db.collection('reports')
  .where('barangay', '==', 'San Pedro')
  .get()
  .then(snapshot => {
    snapshot.forEach(doc => {
      doc.ref.update({ barangay: 'San Miguel' });
    });
  });

// Update "Tibig" to "Tubuan"
db.collection('reports')
  .where('barangay', '==', 'Tibig')
  .get()
  .then(snapshot => {
    snapshot.forEach(doc => {
      doc.ref.update({ barangay: 'Tubuan' });
    });
  });
```

Or manually update them through Firebase Console if there are only a few.

---

**Official list now matches Municipality of Pila records!** 🇵🇭
