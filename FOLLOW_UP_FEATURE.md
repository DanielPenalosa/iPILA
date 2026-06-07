# Report Follow-Up Feature

## Overview
Users can now follow existing reports instead of creating duplicates, increasing priority and notifying admins of community concern.

## Key Features Implemented

### 1. Follow/Unfollow Reports
- **Location**: `report_detail_screen.dart`
- Users can follow reports they didn't create
- Shows follower count and follow status
- Cannot follow own reports

### 2. Smart Duplicate Detection
- **Location**: `submit_report_screen.dart`
- Automatically detects similar reports based on:
  - Same category and barangay
  - Similar descriptions (40%+ keyword match)
  - Nearby location (within 100 meters)
- Shows enhanced dialog encouraging users to follow existing reports

### 3. Priority System
- Reports automatically get priority based on follower count:
  - 20+ followers: **Priority 5** (Critical)
  - 10-19 followers: **Priority 4** (High)
  - 5-9 followers: **Priority 3** (Medium)
  - 2-4 followers: **Priority 2** (Low)
  - 0-1 followers: **Priority 1** (Normal)

### 4. Admin Notifications
- **Location**: `report_service.dart` - `_notifyAdminAboutFollower()`
- Admins receive notifications when users follow reports:
  - **First follower**: "New Report Follow-Up" - includes user name and report details
  - **5+ followers**: "High Priority Report" - warns that issue needs attention
  - **General**: Shows follower count and encourages prioritization

### 5. Community Reports Sorting
- Reports are sorted by priority (followers) first, then by date
- High-priority reports appear at the top of community feed

## User Flow

### When Submitting a New Report:
1. User fills out report details
2. System checks for similar existing reports
3. If found, shows enhanced dialog with:
   - Explanation that issue already exists
   - Visual preview of similar reports with status
   - Follower counts displayed
   - Three options:
     - **Cancel** - return to form
     - **View Report** - see the existing report
     - **Follow & Support** - follow the report and notify admin

### When Following a Report:
1. User clicks "Follow Report" button
2. Follower count increases
3. Report priority automatically recalculated
4. Admin receives notification about the follow-up
5. User can view report and receive status updates

## Benefits

### For Citizens:
- No duplicate report creation
- Join others concerned about same issue
- Higher visibility = faster response
- Stay informed on progress

### For Admins:
- Clear indication of community priorities
- Notifications when reports gain followers
- Reduced duplicate reports
- Better resource allocation

## Technical Implementation

### Database Fields Added to Report Model:
```dart
followers: List<String>        // UIDs of users following
followerCount: int             // Number of followers
priority: int                  // Auto-calculated (1-5)
```

### Key Methods:
- `followReport(reportId, userId)` - Add user to followers
- `unfollowReport(reportId, userId)` - Remove user from followers
- `getFollowUpReports({minFollowers})` - Get high-priority reports
- `findSimilarReports(...)` - Detect duplicates
- `_notifyAdminAboutFollower(...)` - Send admin notifications

## UI Components

### Report Detail Screen:
- Follow/Unfollow button (not shown for own reports)
- Follower count badge
- Visual indicator when following

### Community Reports Screen:
- Follower count displayed on each card
- Priority badges for high-priority reports
- Sorted by priority

### Submit Report Screen:
- Enhanced duplicate detection dialog
- Visual report previews with status
- Clear call-to-action buttons

## Future Enhancements (Optional)
- Push notifications for followers when report status changes
- Follower list view (see who else is following)
- Email digests for followed reports
- Geographic clustering of similar reports on map view
