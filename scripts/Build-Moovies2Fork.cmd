@echo off
setlocal

set "ROOT=%~dp0.."
set "WORK=%ROOT%\apk-work"
set "JAVA=C:\Users\johns\scoop\apps\temurin17-jdk\current\bin\java.exe"
set "APKTOOL=C:\Users\johns\scoop\apps\apktool\current\apktool.jar"

cd /d "%WORK%"
"%JAVA%" -jar "%APKTOOL%" b moovies2-src -o Moovies2-unsigned.apk

endlocal