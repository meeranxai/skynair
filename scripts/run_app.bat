@echo off
echo Starting G-Network App...
cd /d "%~dp0"
flutter run -d chrome --web-port=8080
pause