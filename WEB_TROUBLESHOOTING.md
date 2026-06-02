# Web Troubleshooting Guide

## Location Permission Issues on Web

When testing location features on web (localhost or deployed), you may encounter "Location permission permanently denied" errors. Here's how to fix:

### For Development (localhost)

1. **Chrome/Edge:**
   - Click the lock icon in address bar
   - Go to "Site settings"
   - Find "Location" and set to "Allow"
   - Refresh the page

2. **Firefox:**
   - Click the lock icon in address bar
   - Click "More information"
   - Go to "Permissions" tab
   - Uncheck "Use Default" for Location
   - Select "Allow"
   - Refresh the page

### For Production (Railway/deployed site)

**Important:** Most browsers require HTTPS for geolocation API to work properly.

1. Railway automatically provides HTTPS
2. Make sure users allow location when prompted
3. If permission was denied:
   - Click lock icon in address bar
   - Reset permissions
   - Refresh and allow when prompted again

### Fallback for Testing

If you can't get location permissions working:
- The system allows manual barangay selection
- Users can still submit reports without exact GPS coordinates
- Consider adding manual coordinate input for testing

## Image Upload on Web

Images now display correctly on web after upload using:
- `XFile` for web (instead of `File`)
- `Image.network()` for web preview (instead of `Image.file()`)
- `CloudinaryService.uploadImageWeb()` for web uploads

## Other Web-Specific Notes

- Some mobile-specific features (camera, notifications) may have limited support on web
- Always test on actual deployed URL, not just localhost
- Browser console (F12) shows helpful error messages
