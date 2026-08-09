# Admin Features Implementation Plan

## Features to Implement

### 1. Priority Levels ✓
- Add `priorityLevel` field: 'urgent', 'high', 'medium', 'low'
- Color coding: Red (urgent), Orange (high), Yellow (medium), Gray (low)
- Admin can set priority level when viewing report
- Show priority badge on report cards
- Filter/sort by priority in reports list

### 2. Before/After Photos ✓
- Add `progressPhotos` array field with timestamp
- Structure: `[{url: string, type: 'before'|'after'|'progress', uploadedAt: timestamp, uploadedBy: string}]`
- Admin can upload multiple progress photos
- Show photo gallery in report detail with before/after comparison
- Automatic "before" from initial report photos

### 3. Bulk Actions ✓
- Multi-select checkbox on report cards
- Bulk action bar appears when items selected
- Actions: Change Status, Assign To, Set Priority, Delete
- Confirmation dialog before bulk operations
- Progress indicator for bulk operations

### 4. Response Templates ✓
- Add templates collection in Firestore
- Pre-defined quick replies: "Under Review", "Work Started", "Need More Info", "Completed"
- Admin can create/edit/delete templates in Settings
- Template picker when adding status update
- Variables: {reporter_name}, {category}, {barangay}, {date}

## Implementation Status
- [x] Planning
- [ ] Priority Levels - Model Update
- [ ] Priority Levels - UI Implementation  
- [ ] Progress Photos - Model Update
- [ ] Progress Photos - Upload UI
- [ ] Bulk Actions - Selection UI
- [ ] Bulk Actions - Action Handler
- [ ] Response Templates - Database
- [ ] Response Templates - UI

## Files to Modify
1. `lib/data/models/report_model.dart` - Add new fields
2. `lib/features/admin/screens/admin_reports_screen.dart` - Bulk selection UI
3. `lib/features/admin/screens/admin_report_detail_screen.dart` - Priority picker, photo upload
4. `lib/features/admin/screens/admin_settings_screen.dart` - Template management
5. `lib/features/reports/widgets/report_card.dart` - Priority badge display
6. `lib/data/services/report_service.dart` - Bulk operations
7. `lib/core/constants/app_constants.dart` - Priority constants

## Database Schema Changes

### Reports Collection
```
{
  ...existing fields,
  priorityLevel: 'medium', // 'urgent' | 'high' | 'medium' | 'low'
  progressPhotos: [
    {
      url: 'https://...',
      type: 'before' | 'after' | 'progress',
      uploadedAt: Timestamp,
      uploadedBy: 'admin@email.com',
      caption: 'Work in progress'
    }
  ]
}
```

### Response Templates Collection (New)
```
{
  id: 'auto-id',
  title: 'Under Review',
  content: 'Hello {reporter_name}, we have received your report about {category}...',
  category: 'status_update' | 'completion' | 'request_info',
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```
