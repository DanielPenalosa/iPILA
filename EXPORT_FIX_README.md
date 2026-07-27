# Export Feature White Screen Fix

## Issue
The "Export All Reports" feature causes a white screen with Flutter assertion error after downloading the CSV file.

## Root Cause
The issue is caused by using `showDialog()` and `Navigator.pop()` during async operations. When the download happens, the widget tree gets disposed but the code still tries to pop the dialog, causing the assertion failure.

## Temporary Workaround
Until the fix is properly deployed, you can use these steps:

1. **After clicking "Export All Reports"**:
   - The file WILL download successfully
   - If screen goes white, press F5 to refresh the page
   - You'll be back at login - just log in again
   - The CSV file will be in your Downloads folder

2. **The CSV file contains**:
   - All report IDs, categories, descriptions
   - Barangay, address, coordinates
   - Status, reporter names
   - Timestamps and follower counts

## Proper Fix (In Progress)
Replace the dialog-based loading indicator with a SnackBar-based one:
- Use `ScaffoldMessenger.showSnackBar()` for loading state
- Use `messenger.hideCurrentSnackBar()` before showing success/error
- No dialogs = no Navigator.pop() issues

## Alternative: Desktop App
If you need to export frequently, consider using the desktop version where this issue doesn't occur.
