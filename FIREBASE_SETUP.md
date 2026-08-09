# iPILA Firebase Setup Guide

## 1. Authentication

Firebase Console → Authentication → Sign-in method

- Enable **Email/Password**

---

## 2. Firestore Security Rules

Firebase Console → Firestore Database → Rules → Paste → Publish

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write, delete: if request.auth != null;
    }
  }
}
```

---

## 3. Firestore Indexes

Firebase Console → Firestore Database → Indexes → Composite → Add index

| Collection   | Field 1              | Field 2              |
|--------------|----------------------|----------------------|
| `reports`    | `userId` ASC         | `createdAt` DESC     |
| `reports`    | `currentStatus` ASC  | `createdAt` DESC     |
| `reports`    | `barangay` ASC       | `createdAt` DESC     |
| `users`      | `role` ASC           | `createdAt` DESC     |
| `ordinances` | `isActive` ASC       | `dateEnacted` DESC   |
| `ordinances` | `category` ASC       | `dateEnacted` DESC   |

---

## 4. Admin Account

### Step 1 — Create the Firebase Auth user
Firebase Console → Authentication → Users → Add user

```
Email:    admin@pila.gov.ph
Password: (your secure password)
```

### Step 2 — Create the Firestore document
Firebase Console → Firestore → users → Add document

Document ID: (paste the UID from the Auth user above)

```
fullName:       "LGU Admin"
email:          "admin@pila.gov.ph"
phone:          "09000000000"
barangay:       "Pila"
role:           "superadmin"
approvalStatus: "approved"
isActive:       true
photoUrl:       null
idPhotoUrl:     null
createdAt:      (Timestamp — today)
```

---

## 5. FAQs Collection

Firebase Console → Firestore → Start collection → ID: `faqs`

### Document 1 (auto-ID)
```
question: "How do I report an issue?"
answer:   "Tap the + button at the bottom of the home screen, fill in the category, add a photo, capture your GPS location, then tap Submit Report."
order:    1
```

### Document 2 (auto-ID)
```
question: "How long does it take to resolve a report?"
answer:   "The LGU aims to respond within 3-5 business days. You can track the live status of your report in the My Reports tab."
order:    2
```

### Document 3 (auto-ID)
```
question: "Can I submit a report anonymously?"
answer:   "No. All reports require user authentication to ensure accountability and enable effective follow-up communication. This helps the LGU verify report authenticity, prevent spam or duplicate submissions, and maintain direct contact with you for updates, clarifications, or resolution confirmation."
order:    3
```

### Document 4 (auto-ID)
```
question: "How do I contact the Municipal Hall?"
answer:   "You can reach the Municipality of Pila at (049) 559-0000 or visit the Municipal Hall at Pila, Laguna (8AM-5PM, Mon-Fri)."
order:    4
```

### Document 5-14 (auto-ID)
Additional FAQs covering report editing, community reports, ordinances viewing, follow-up feature, notifications, privacy, photo attachments, and location accuracy. See `seed_database.dart` for complete list.

---

## 6. Ordinances Collection

Firebase Console → Firestore → Start collection → ID: `ordinances`

### Document 1 (auto-ID)
```
title:       "Solid Waste Management Ordinance"
number:      "2023-001"
category:    "Waste Management"
description: "An ordinance regulating solid waste collection and disposal in the Municipality of Pila."
content:     "Section 1. All residents are required to segregate biodegradable and non-biodegradable waste. Section 2. Garbage collection schedule shall be posted in each barangay hall. Section 3. Violations shall be subject to fines as prescribed by RA 9003."
fileUrl:     null
dateEnacted: (Timestamp — 2023-05-01)
createdAt:   (Timestamp — today)
isActive:    true
tags:        ["waste", "environment", "sanitation"]
```

### Document 2 (auto-ID)
```
title:       "Anti-Littering Ordinance"
number:      "2022-005"
category:    "Environment"
description: "An ordinance prohibiting littering in public places within the Municipality of Pila."
content:     "Section 1. It is prohibited to throw, dump, or deposit garbage in any public place. Section 2. Violators shall be fined P500 for the first offense, P1,000 for the second, and P2,000 plus community service for the third."
fileUrl:     null
dateEnacted: (Timestamp — 2022-03-15)
createdAt:   (Timestamp — today)
isActive:    true
tags:        ["littering", "environment", "public"]
```

---

## 7. Notifications Collection

Auto-created when admin sends alerts. No manual setup needed.

---

## 8. Cloudinary Setup

1. Sign up at https://cloudinary.com (free tier)
2. Dashboard → Settings → Upload → Upload presets → Add upload preset
   - Name: `ipila_uploads`
   - Signing mode: **Unsigned**
   - Save
3. Your Cloud Name is shown on the dashboard homepage
4. Already configured in `lib/data/services/cloudinary_service.dart`

---

## Final Checklist

- [ ] Email/Password auth enabled
- [ ] Firestore rules published
- [ ] Composite indexes created (6 total)
- [ ] Admin user created in Auth + Firestore document added
- [ ] `faqs` collection seeded (4 documents)
- [ ] `ordinances` collection seeded (2 documents)
- [ ] Cloudinary unsigned preset `ipila_uploads` created
