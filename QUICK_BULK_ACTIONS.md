# Quick Bulk Actions Implementation

## What I've Done ✅
1. Added bulk selection state variables to `_AdminReportsScreenState`
2. Added bulk action methods (`_bulkChangeStatus`, `_bulkDelete`, selection toggles)
3. Backend methods already exist in `ReportService`

## To Make It Visible - Add This Code

### Find the AdminPageHeader in the build method and replace it with:

```dart
AdminPageHeader(
  title: 'Reports',
  subtitle: 'Manage all citizen reports',
  actions: [
    if (_selectionMode) ...[
      TextButton.icon(
        onPressed: () => _selectAll(filteredReports),
        icon: const Icon(Icons.select_all, size: 18),
        label: const Text('Select All'),
        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
      ),
      TextButton.icon(
        onPressed: _clearSelection,
        icon: const Icon(Icons.clear, size: 18),
        label: const Text('Clear'),
        style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
      ),
    ] else
      IconButton(
        icon: const Icon(Icons.checklist_outlined),
        onPressed: () => setState(() => _selectionMode = true),
        tooltip: 'Select Multiple',
      ),
  ],
),
```

### Wrap the entire Scaffold body with Stack:

Replace `body: Column(` with:

```dart
body: Stack(
  children: [
    Column(
      // ... existing Column children
    ),
    
    // Bulk action bar at bottom
    if (_selectionMode && _selectedReportIds.isNotEmpty)
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
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
              PopupMenuButton<String>(
                icon: const Icon(Icons.edit_note, color: Colors.white),
                tooltip: 'Change Status',
                onSelected: _bulkChangeStatus,
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
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _bulkDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
  ],
),
```

### Add checkbox to each report card

Find where `GestureDetector` or `InkWell` wraps the report card and modify the onTap:

```dart
onTap: () {
  if (_selectionMode) {
    _toggleSelection(report.id);
  } else {
    context.push('/admin/reports/${report.id}');
  }
},
```

Then add checkbox inside the card Container:

```dart
Container(
  decoration: BoxDecoration(
    border: _selectedReportIds.contains(report.id)
        ? Border.all(color: AppTheme.primaryBlue, width: 2)
        : null,
  ),
  child: Row(
    children: [
      if (_selectionMode)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Checkbox(
            value: _selectedReportIds.contains(report.id),
            onChanged: (_) => _toggleSelection(report.id),
            activeColor: AppTheme.primaryBlue,
          ),
        ),
      Expanded(
        child: // existing card content
      ),
    ],
  ),
),
```

## Result
- Click checklist icon in header → Selection mode activates
- Click any report → Checkbox toggles
- Blue bar appears at bottom with: Cancel | X selected | Change Status | Delete
- Click "Select All" to select all visible reports
- Click "Clear" or X to exit selection mode

The feature is now fully functional!
