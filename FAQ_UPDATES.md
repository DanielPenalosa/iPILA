# FAQ Updates

## Changes Made

### 1. Anonymous Reporting Answer Changed
**Question:** "Can I submit a report anonymously?"

**Old Answer:** "Yes. When submitting a report, toggle the Submit Anonymously switch. Your name will not be visible to the public."

**New Answer:** "No. All reports require user authentication to ensure accountability and enable effective follow-up communication. This helps the LGU verify report authenticity, prevent spam or duplicate submissions, and maintain direct contact with you for updates, clarifications, or resolution confirmation."

**Reason:** Authentication is required for all reports to maintain accountability, prevent abuse, and enable proper follow-up communication.

---

## 2. New FAQs Added (Total: 14 FAQs)

### FAQ 7: Can I edit or delete my report after submission?
- Explains that reports cannot be modified after submission to maintain data integrity
- Provides guidance on how to update information through alternative channels

### FAQ 8: What is the Community Reports section?
- Explains the public community reports feature
- Describes the follow-up functionality for showing support

### FAQ 9: How do I view municipal ordinances?
- Guides users to the Laws tab
- Explains search and browsing capabilities

### FAQ 10: What does it mean to follow-up on a report?
- Clarifies the follow-up feature's purpose
- Explains notification benefits

### FAQ 11: Will I receive notifications about my reports?
- Details the notification system
- Lists notification triggers (status changes, admin comments)

### FAQ 12: Is my personal information safe?
- Reassures users about data security
- Mentions Firebase Authentication and security rules
- Clarifies privacy policies

### FAQ 13: Can I attach photos to my report?
- Confirms photo attachment capability (up to 3 photos)
- Provides best practices for photo submissions

### FAQ 14: What if my report location is incorrect?
- Troubleshoots location accuracy issues
- Explains GPS capture process
- Reassures about approximate location usefulness

---

## Implementation

### Files Updated:
1. `lib/seed_database.dart` - Updated FAQ seed data with 14 comprehensive FAQs
2. `FIREBASE_SETUP.md` - Updated documentation
3. `lib/features/help/screens/faq_screen.dart` - NEW: Created dedicated FAQ screen
4. `lib/core/utils/app_router.dart` - Added `/faq` route
5. `lib/features/home/widgets/pilabot_widget.dart` - Added "View all FAQs" option

### How to Access FAQs:
1. **Via PilaBot**: Tap the PilaBot floating button → Click "View all FAQs"
2. **Direct Navigation**: Navigate to `/faq` route from anywhere in the app

### Features:
- Expandable/collapsible FAQ cards
- Real-time search functionality
- Auto-synced with Firestore
- Smooth animations and modern UI
- Mobile-optimized design

### To Apply Changes:
Run the seed database script to populate the new FAQs in Firestore:
```dart
// In your app, call:
await SeedDatabase.seed();
```

Or manually add the new FAQs to Firestore console following the structure in `seed_database.dart`.

---

## Benefits

- **Improved User Understanding**: More comprehensive coverage of common questions
- **Better Transparency**: Clear explanation about authentication requirements
- **Enhanced User Experience**: Users can find answers without contacting support
- **Reduced Support Load**: Self-service information for common inquiries
