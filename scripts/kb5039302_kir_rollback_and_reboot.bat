@echo off
cls
echo ===============================================
echo    KIR Rollback Script for KB5039302
echo ===============================================
echo.

echo [INFO] Updating registry to apply KIR Rollback...
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 1931709068 /t REG_DWORD /d 0 /f
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Failed to update the registry.
    exit /b 1
) else (
    echo [SUCCESS] Registry updated successfully.
)
echo.

echo [INFO] Initiating forced system restart with automatic app recovery...
shutdown /g /f /t 60 /c "System will force restart in 60 seconds to apply changes."

echo [INFO] Shutdown command issued. The system will restart shortly.
exit /b 0
