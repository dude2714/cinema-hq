@echo off
setlocal

set "ROOT=%~dp0.."
set "TOOLS=C:\Users\johns\OneDrive\Desktop\empty folder\cinema\.tools"
set "JAVA=C:\Users\johns\scoop\apps\temurin17-jdk\current\bin\java.exe"
set "APK=%ROOT%\apk-work\Moovies2-unsigned.apk"

cd /d "%TOOLS%"
"%JAVA%" -jar uber-apk-signer-1.3.0.jar -a "%APK%" --overwrite

endlocal