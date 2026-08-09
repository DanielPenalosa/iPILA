# Bulk Actions Implementation Guide

## Completed ✓
1. Added bulk action methods to `ReportService`:
   - `bulkUpdateStatus()` - Change status for multiple reports
   - `bulkDeleteReports()` - Delete multiple reports
   - `bulkAssignReports()` - Assign multiple reports to admin

## To Implement

### Step 1: Update `_AdminReportsScreenState` class

Add these state variables at the top of the class:
```dart
bool _selectionMode = false;
final Set<String> _selectedReportIds = {};
```

### Step 2: Add selection toggle method
```dart
void _toggleSelection(String reportId) {
  setState(() {
    if (_selectedReportIds.contains(reportId)) {
      _selectedReportIds.remove(reportId);
      if (_selectedReportIds.isEmpty) {
        _selectionMode = false;
      }
    } else {
      _selectedReportIds.add(reportId);
      _selectionMode = true;
    }
  });
}

void _selectAll(List<ReportModel> reports) {
  setState(() {
    _selectedReportIds.addAll(reports.map((r) => r.id));
    _selectionMode = true;
  });
}

void _clearSelection() {
  setState(() {
    _selectedReportIds.clear();
    _selectionMode = false;
  });
}
```

### Step 3: Add bulk action methods
```dart
Future<void> _bulkChangeStatus(String newStatus) async {
  if (_selectedReportIds.isEmpty) return;
  
  final auth = context.read<AuthProvider>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Change Status for ${_selectedReportIds.length} Reports'),
      content: Text('Set status to "$newStatus" for all selected reports?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await _service.bulkUpdateStatus(
      reportIds: _selectedReportIds.toList(),
      newStatus: newStatus,
      adminEmail: auth.user?.email ?? '',
    );
    
    _clearSelection();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Updated ${_selectedReportIds.length} reports'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }
}

Future<void> _bulkDelete() async {
  if (_selectedReportIds.isEmpty) return;
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Delete ${_selectedReportIds.length} Reports'),
      content: const Text('This action cannot be undone. Continue?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    await _service.bulkDeleteReports(_selectedReportIds.toList());
    _clearSelection();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Reports deleted'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
    }
  }
}
```

### Step 4: Add bulk action bar widget

Add this at the bottom of the file before the last closing brace:

```dart
Widget _buildBulkActionBar() {
  return Container(
    height: 60,
    color: AppTheme.primaryBlue,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _clearSelection,
          tooltip: 'Cancel',
        ),
        const SizedBox(width: 8),
        Text(
          '${_selectedReportIds.length} selected',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        // Change Status
        PopupMenuButton<String>(
          icon: const Icon(Icons.edit_note, color: Colors.white),
          tooltip: 'Change Status',
          onSelected: (status) => _bulkChangeStatus(status),
          itemBuilder: (context) => [
            'Validated',
            'Queued',
            'In Progress',
            'Completed',
            'Rejected',
          ].map((status) => PopupMenuItem(
            value: status,
            child: Text(status),
          )).toList(),
        ),
        const SizedBox(width: 8),
        // Delete
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: _bulkDelete,
          tooltip: 'Delete',
        ),
      ],
    ),
  );
}
```

### Step 5: Update report card to show checkbox

In the `_ReportCard` widget (or wherever report cards are built), wrap with:

```dart
return InkWell(
  onTap: () {
    if (selectionMode) {
      onSelect?.call();
    } else {
      // Normal navigation
      context.push('/admin/reports/${report.id}');
    }
  },
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: isSelected 
        ? Border.all(color: AppTheme.primaryBlue, width: 2)
        : null,
    ),
    child: Row(
      children: [
        if (selectionMode)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Checkbox(
              value: isSelected,
              onChanged: (_) => onSelect?.call(),
              activeColor: AppTheme.primaryBlue,
            ),
          ),
        Expanded(
          child: // ... existing card content
        ),
      ],
    ),
  ),
);
```

### Step 6: Update build method

Wrap your Scaffold body with:

```dart
body: Stack(
  children: [
    // Existing content (StreamBuilder with list)
    ...,
    
    // Bulk action bar (show when selection mode active)
    if (_selectionMode)
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: _buildBulkActionBar(),
      ),
  ],
),
```

### Step 7: Add "Select All" button to AppBar

In the AppBar actions, add:

```dart
if (_selectionMode)
  TextButton(
    onPressed: () => _selectAll(filteredReports),
    child: const Text(
      'Select All',
      style: TextStyle(color: AppTheme.primaryBlue),
    ),
  ),
```

## Testing

1. Go to Admin Reports screen
2. Long-press or click checkbox on any report card
3. Selection mode activates, checkboxes appear
4. Select multiple reports
5. Use bulk action bar at bottom to:
   - Change status for all
   - Delete all selected
6. Click X to cancel selection mode

## Files Modified
- ✅ `lib/data/services/report_service.dart` - Added bulk methods
- ⏳ `lib/features/admin/screens/admin_reports_screen.dart` - Add UI (follow guide above)

The implementation is ~300 lines. Follow the steps above to integrate into your existing admin reports screen.
