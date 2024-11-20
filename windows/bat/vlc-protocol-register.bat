@echo off
setlocal EnableDelayedExpansion

:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Error: This script requires Administrator privileges.
    echo Please right-click on this file and select "Run as Administrator".
    echo.
    pause
    exit /b 1
)

:: Check for VLC executable
if not exist "%~dp0vlc.exe" (
    echo Error: Cannot find vlc.exe
    echo Please put these files in your VLC directory and try again.
    echo.
    pause
    exit /b 1
)

echo Registering vlc:// protocol handler...
echo.

:: Register protocol handler
reg add "HKCR\vlc" /ve /t REG_SZ /d "URL:vlc Protocol" /f

reg add "HKCR\vlc" /v "URL Protocol" /t REG_SZ /d "" /f

reg add "HKCR\vlc\DefaultIcon" /ve /t REG_SZ /d "\"%~dp0vlc.exe\",0" /f

reg add "HKCR\vlc\shell\open\command" /ve /t REG_SZ /d "\"%~dp0vlc-protocol.bat\" \"%%1\"" /f

:: Verify registration
reg query "HKCR\vlc\shell\open\command" /ve
if %errorLevel% neq 0 (
    echo Error: Failed to verify registration.
    pause
    exit /b 1
)

echo Successfully registered vlc:// protocol handler!
echo You can now use vlc:// links in your browser.
echo.
pause
