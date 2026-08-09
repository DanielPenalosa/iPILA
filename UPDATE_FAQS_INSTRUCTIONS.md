# How to Update FAQs in Your Running App

## Quick Solution ✅

### Use the Admin Settings Button (EASIEST!)
1. Log in as admin
2. Go to **Admin → Settings**
3. Click **"System"** section in the left sidebar
4. Under "Data Management", click **"Update FAQs"** button
5. Wait for success message
6. Refresh the page and check **Ordinances & FAQs** tab

**This will:**
- Update the anonymous reporting FAQ (#3) to say "No" with explanation
- Add 8 new FAQs (orders 7-14)
- Update existing FAQs if needed

---

## Alternative Solutions

### Option 1: Run Seed Database
If you have a way to trigger the seed database function in your running app:

1. Add a button in Admin Settings or use the developer console
2. Call `SeedDatabase.seed()` 
3. This will update all FAQs without deleting existing ones

### Option 2: Manual Update via Firebase Console
Go to Firebase Console → Firestore Database → `faqs` collection

#### Update FAQ #3 (Anonymous Reporting)
Find the document where `order = 3` and update:
```
answer: "No. All reports require user authentication to ensure accountability and enable effective follow-up communication. This helps the LGU verify report authenticity, prevent spam or duplicate submissions, and maintain direct contact with you for updates, clarifications, or resolution confirmation."
```

#### Add New FAQs (order 7-14)

**FAQ 7:**
```
question: "Can I edit or delete my report after submission?"
answer: "No. Once submitted, reports cannot be edited or deleted to maintain data integrity. If you need to update information, contact the Municipal Hall directly or add a comment in the report details."
order: 7
```

**FAQ 8:**
```
question: "What is the Community Reports section?"
answer: "Community Reports lets you see all public reports submitted by other residents in your area. You can follow-up on reports to show support and track progress on issues affecting your community."
order: 8
```

**FAQ 9:**
```
question: "How do I view municipal ordinances?"
answer: "Tap the Laws tab at the bottom navigation. You can browse all municipal ordinances, search by keyword or category, and view full ordinance details including enforcement dates and penalties."
order: 9
```

**FAQ 10:**
```
question: "What does it mean to follow-up on a report?"
answer: "Following-up on a report shows your support for that issue and helps prioritize community concerns. You will also receive notifications when the report status changes."
order: 10
```

**FAQ 11:**
```
question: "Will I receive notifications about my reports?"
answer: "Yes. You will receive push notifications when your report status changes (validated, queued, in progress, completed) or when administrators add comments or updates."
order: 11
```

**FAQ 12:**
```
question: "Is my personal information safe?"
answer: "Yes. iPILA uses Firebase Authentication and Firestore security rules to protect your data. Your personal information is only visible to LGU administrators and is never shared publicly."
order: 12
```

**FAQ 13:**
```
question: "Can I attach photos to my report?"
answer: "Yes. You can attach up to 3 photos when submitting a report. Clear photos help administrators assess the issue and prioritize response. Make sure images are relevant and show the problem clearly."
order: 13
```

**FAQ 14:**
```
question: "What if my report location is incorrect?"
answer: "Make sure location services are enabled on your device. The app automatically captures your GPS coordinates when you submit a report. If the pin is slightly off, administrators can still identify the general area."
order: 14
```

### Option 3: Quick Admin Function
Add this temporary function to your admin settings screen to update FAQs with one click.

---

## After Updating
1. Refresh your browser/app
2. Navigate to Ordinances & FAQs tab
3. The new content should appear immediately
