# Admin Report Detail Screen Fix

## Current Problem
The admin report detail screen is using the OLD service signature which doesn't work with the new validation system.

## Required Changes in `admin_report_detail_screen.dart`

###  1. Add Missing Field (line 27)
```dart
// ADD THIS LINE:
final _remarksCtrl = TextEditingController();
```

### 2. Update dispose method (line 33)
```dart
@override
void dispose() {
  _disposed = true;
  _noteCtrl.dispose();
  _remarksCtrl.dispose(); // ADD THIS LINE
  super.dispose();
}
```

### 3. Replace _updateStatus method (starting around line 49)
```dart
Future<void> _updateStatus(
  String reportId,
  String newStatus,
  String adminName,
) async {
  if (_disposed || !mounted) return;

  setState(() => _isUpdating = true);
  try {
    // CHANGED: Service now returns Map, not void
    final result = await _service.updateStatus(
      reportId: reportId,
      newStatus: newStatus,
      updatedBy: adminName,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      adminRemarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(), // NEW
      afterPhoto: _afterPhoto,
      afterPhotoWeb: null, // Web not supported in admin yet
    );

    if (!_disposed && mounted) {
      // CHANGED: Check result
      if (result['success'] == true) {
        _noteCtrl.clear();
        _remarksCtrl.clear(); // NEW
        setState(() => _afterPhoto = null);
        AppToast.show(
          context,
          'Status updated to $newStatus',
          type: ToastType.success,
        );
      } else {
        // SHOW ERROR from validation
        AppToast.show(
          context,
          result['error'] ?? 'Failed to update status',
          type: ToastType.error,
        );
      }
    }
  } catch (e) {
    if (!_disposed && mounted) {
      AppToast.show(
        context,
        'Error: ${e.toString()}',
        type: ToastType.error,
      );
    }
  } finally {
    if (!_disposed && mounted) setState(() => _isUpdating = false);
  }
}
```

### 4. Update _showUpdateDialog method (around line 79)
**Find the section where it builds the TextField for notes and ADD after it:**

```dart
// AFTER the note TextField, ADD this for Completed status:
if (selectedStatus == AppConstants.statusCompleted) ...[
  const SizedBox(height: 12),
  // ADD Requirements info box
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            Text(
              'Completion Requirements',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '• Before photo: ${report.photoUrls.isNotEmpty ? '✓ Available' : '✗ Missing'}\n'
          '• After photo: ${_afterPhoto != null ? '✓ Selected' : '✗ REQUIRED'}',
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    ),
  ),
  const SizedBox(height: 12),
  // ADD Admin remarks field
  TextField(
    controller: _remarksCtrl,
    decoration: const InputDecoration(
      labelText: 'Resolution Details (recommended)',
      hintText: 'Describe what was done to resolve this...',
      helperText: 'This will be shown to residents',
    ),
    maxLines: 3,
  ),
  const SizedBox(height: 12),
  // The existing After Photo button stays here
],
```

### 5. Update the "Update Status" button logic (around line 130)
**Find the AdminHoverButton with label 'Update Status' and REPLACE its onTap:**

```dart
onTap: selectedStatus == null
    ? null
    : () {
        // ADD VALIDATION
        if (selectedStatus == AppConstants.statusCompleted) {
          if (_afterPhoto == null) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('After photo is required to complete!'),
                backgroundColor: AppTheme.primaryRed,
              ),
            );
            return; // Don't proceed
          }
        }
        
        final status = selectedStatus!;
        if (Navigator.canPop(ctx)) {
          Navigator.pop(ctx);
        }
        _updateStatus(report.id, status, adminName);
      },
```

## Why These Changes Are Needed

1. **Service Signature Changed**: The `updateStatus` method now returns `Map<String, dynamic>` with validation results
2. **Validation Required**: Must check `result['success']` and show `result['error']` if validation fails
3. **Admin Remarks**: Need to collect and pass completion remarks to the service
4. **Photo Validation**: Frontend must validate before attempting to complete
5. **Error Handling**: Must show validation errors to admin so they know what's missing

## Testing After Fix

1. Try to complete a report WITHOUT after photo → Should show error
2. Try to complete WITH after photo → Should succeed and upload
3. Check that before/after photos appear in both admin and user screens
4. Verify completion remarks are displayed

## Quick Fix Alternative

If manual changes are too complex, the screen can be regenerated from scratch using the enhanced patterns shown above.
