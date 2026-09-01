@echo off
setlocal

set "ADB=C:\Users\johns\AppData\Local\Microsoft\WinGet\Packages\Google.PlatformTools_Microsoft.Winget.Source_8wekyb3d8bbwe\platform-tools\adb.exe"
set "APK=%~dp0..\apk-work\Moovies2-unsigned.apk"
set "SERIAL=0321418026779"

"%ADB%" -s %SERIAL% install -r "%APK%"

endlocal