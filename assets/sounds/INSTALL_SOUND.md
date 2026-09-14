# Install Notification Sound

The notification sound file is missing. Follow these steps to add it:

## Quick Steps:

1. **Download a notification sound** (5-10 seconds, MP3 format)
   - Option 1: https://notificationsounds.com/notification-sounds (choose any bell/alarm)
   - Option 2: https://soundbible.com/tags-alarm.html (download and convert to MP3)
   - Option 3: Use any notification/alarm sound you like

2. **Convert to MP3** if needed
   - Use: https://cloudconvert.com/to/mp3
   - Or use online converter

3. **Rename the file** to exactly: `notification.mp3`

4. **Place it in this folder**: `ipila/assets/sounds/notification.mp3`

5. **Restart the Flutter app**

## Recommended Sounds:

### Free Sound Libraries:
- **Notification Sounds**: https://notificationsounds.com/
  - "Elegant" - Nice bell sound
  - "Alarm Clock" - Attention grabbing
  - "Cheerful" - Pleasant alert

- **Freesound.org**: https://freesound.org/search/?q=notification+alarm
  - Search: "notification alarm"
  - Filter: MP3, Duration 5-10s

- **Zapsplat**: https://www.zapsplat.com/sound-effect-category/alarms-and-sirens/
  - Free alarm sounds

### Sound Requirements:
- **Format**: MP3
- **Duration**: 5-10 seconds (for good loop)
- **Style**: Bell, chime, or alarm sound
- **Volume**: Medium to loud
- **File size**: Under 1MB

## Test After Installing:

1. Go to Admin Reports screen
2. Click the orange "Show Test Popup" button
3. You should hear the sound playing in a loop
4. Check browser console for: `🔊 Sound loop started successfully`

## If Sound Still Doesn't Work:

Check browser console (F12) for errors like:
- `🔊 Sound loop error: ...`
- Look for permission errors
- Try a different sound file
- Make sure browser audio is not muted
