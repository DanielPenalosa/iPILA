# Report Management Improvements

## Overview
This document outlines improvements to the report management system to add better controls, validations, and user actions for both admins and citizens.

## Features to Implement

### 1. **Admin Side: Prevent Editing Completed Reports**

#### Current Issue:
- Admins can update status of completed reports, potentially changing resolved issues

#### Solution:
Add validation in the admin report detail screen to:
- Disable status update button when report is "Completed"
- Show a locked icon/message indicating the report is finalized
- Add confirmation dialog before marking as "Completed" (already partially implemented)

#### Implementation Steps:
1. In `admin_report_detail_screen.dart`:
   - Check if `report.currentStatus == AppConstants.statusCompleted`
   - Disable or hide the "Update Status" button
   - Show visual indicator (lock icon) that report is locked

2. Add enhanced confirmation dialog for "Completed" status:
   - Warn admin that this action is final
   - Require after photo (already implemented)
   - Ask for final confirmation: "Are you sure? This will lock the report."

---

### 2. **Admin Side: Completion Confirmation Dialog**

#### Current Behavior:
- Simple status update modal with dropdown

#### Improved Behavior:
Create a special confirmation flow when selecting "Completed":
1. First dialog: Upload after photo + add remarks
2. Second dialog: "Are you absolutely sure you want to mark this as completed? This action cannot be undone."
3. Show before/after preview before final confirmation

---

### 3. **Citizen Side: Delete Own Reports**

#### Rules for Deletion:
Citizens can delete their own reports ONLY if:
- Report status is "Pending" (just submitted, not yet reviewed)
- Report status is "Completed" (issue is resolved, cleanup allowed)

Citizens CANNOT delete if:
- Status is "Under Review", "Validated", "Queued", or "In Progress"
- Report is assigned to staff (work in progress)
- Reason: Prevents disruption of ongoing administrative work

#### Implementation:
1. Add "Delete Report" button in citizen's report detail screen
2. Show confirmation dialog
3. Check status and validate deletion rules
4. If valid, call delete service method

---

### 4. **Report Service: Delete Method**

Add delete functionality to `report_service.dart`:
```dart
// Delete a report (citizen can delete own reports with restrictions)
Future<Map<String, dynamic>> deleteReport({
  required String reportId,
  required String userId,
}) async {
  // Get report first to validate
  final reportDoc = await _db
      .collection(AppConstants.reportsCollection)
      .doc(reportId)
      .get();

  if (!reportDoc.exists) {
    return {'success': false, 'error': 'Report not found'};
  }

  final reportData = reportDoc.data()!;
  final reportUserId = reportData['userId'] as String;
  final currentStatus = reportData['currentStatus'] as String;

  // Validation: Only owner can delete
  if (reportUserId != userId) {
    return {
      'success': false,
      'error': 'You can only delete your own reports',
    };
  }

  // Validation: Check if deletion is allowed based on status
  final canDelete = currentStatus == AppConstants.statusSubmitted ||
      currentStatus == AppConstants.statusCompleted;

  if (!canDelete) {
    return {
      'success': false,
      'error':
          'Cannot delete report with status "$currentStatus". Reports in progress cannot be deleted.',
    };
  }

  // Delete the report
  await _db.collection(AppConstants.reportsCollection).doc(reportId).delete();

  return {'success': true};
}
```

---

### 5. **UI Components**

#### Admin Detail Screen Locked State:
```dart
// Show lock indicator for completed reports
if (report.currentStatus == AppConstants.statusCompleted) ...[
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.successGreen.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: AppTheme.successGreen.withValues(alpha: 0.3),
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.lock_outline, color: AppTheme.successGreen),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'This report is completed and locked. No further updates can be made.',
            style: TextStyle(
              color: AppTheme.successGreen,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  ),
],

// Disable update button
AdminHoverButton(
  label: 'Update Status',
  onTap: report.currentStatus == AppConstants.statusCompleted
      ? null // Disabled
      : () => _showUpdateDialog(report, adminName),
  color: report.currentStatus == AppConstants.statusCompleted
      ? Colors.grey
      : AppTheme.primaryBlue,
),
```

#### Citizen Detail Screen Delete Button:
```dart
// Show delete button for own reports
if (isOwnReport) ...[
  const SizedBox(height: 16),
  if (report.currentStatus == AppConstants.statusSubmitted ||
      report.currentStatus == AppConstants.statusCompleted)
    SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showDeleteDialog(report),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Delete Report'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.coral,
          side: const BorderSide(color: AppTheme.coral),
        ),
      ),
    ),
],
```

---

### 6. **Confirmation Dialogs**

#### Delete Confirmation for Citizen:
```dart
void _showDeleteDialog(ReportModel report) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Report?'),
      content: Text(
        report.currentStatus == AppConstants.statusCompleted
            ? 'This completed report will be permanently deleted. This action cannot be undone.'
            : 'Are you sure you want to delete this report? You can only delete reports that haven\'t been reviewed yet.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await _deleteReport(report.id);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.coral,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

Future<void> _deleteReport(String reportId) async {
  final userId = context.read<AuthProvider>().user?.uid;
  if (userId == null) return;

  final result = await ReportService().deleteReport(
    reportId: reportId,
    userId: userId,
  );

  if (mounted) {
    if (result['success'] == true) {
      AppToast.show(
        context,
        'Report deleted successfully',
        type: ToastType.success,
      );
      Navigator.pop(context); // Go back to reports list
    } else {
      AppToast.show(
        context,
        result['error'] ?? 'Failed to delete report',
        type: ToastType.error,
      );
    }
  }
}
```

#### Completion Confirmation for Admin:
```dart
void _showCompletionConfirmation(ReportModel report, String adminName) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.primaryYellow),
          const SizedBox(width: 8),
          const Text('Final Confirmation'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You are about to mark this report as COMPLETED.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text('This means:'),
          const SizedBox(height: 8),
          _bulletPoint('The issue has been fully resolved'),
          _bulletPoint('Before & after photos will be published'),
          _bulletPoint('Citizens will be notified of completion'),
          _bulletPoint('The report will be LOCKED (no further edits)'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '⚠️ This action cannot be undone. Are you absolutely sure?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            _updateStatus(report.id, AppConstants.statusCompleted, adminName);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successGreen,
          ),
          child: const Text('Yes, Mark as Completed'),
        ),
      ],
    ),
  );
}

Widget _bulletPoint(String text) {
  return Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 16)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}
```

---

## Summary of Changes

### Admin Portal:
✅ Prevent status updates on completed reports  
✅ Show lock icon on completed reports  
✅ Enhanced confirmation dialog before completion  
✅ Warning about irreversible action  

### Citizen Portal:
✅ Delete button for own reports  
✅ Delete allowed only for "Pending" or "Completed" status  
✅ Confirmation dialog with clear messaging  
✅ Prevent deletion of in-progress reports  

### Backend:
✅ Add `deleteReport` method with validations  
✅ Status-based deletion rules  
✅ Owner verification  

---

## Implementation Priority

1. **High Priority:**
   - Prevent editing completed reports (admin)
   - Add delete functionality (citizen)
   - Enhanced completion confirmation (admin)

2. **Medium Priority:**
   - UI polish for locked state indicators
   - Better error messages

3. **Low Priority:**
   - Analytics on deleted reports
   - Admin override for special cases

---

## Testing Checklist

- [ ] Admin cannot update completed report status
- [ ] Lock icon shows on completed reports
- [ ] Completion confirmation shows proper warnings
- [ ] Citizen can delete pending reports
- [ ] Citizen can delete completed reports
- [ ] Citizen CANNOT delete in-progress reports
- [ ] Citizen CANNOT delete other user's reports
- [ ] Proper error messages shown
- [ ] Navigation works after deletion
- [ ] Toast notifications work correctly

