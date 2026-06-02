@echo off
echo Generating web icons from logo...
echo.

cd /d "%~dp0"

echo Step 1: Getting dependencies...
call flutter pub get
echo.

echo Step 2: Generating icons...
call dart run flutter_launcher_icons
echo.

echo Step 3: Cleaning build...
call flutter clean
echo.

echo Done! Your web icons have been generated.
echo You can now run: flutter run -d chrome
pause
