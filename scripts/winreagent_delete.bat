REM -------------------------------------------------------------------------------
REM   Author: Limehawk.io
REM   Date:   [06-09-25]
REM   About:  [sentinelone uninstaller]
REM -------------------------------------------------------------------------------

@echo off
if exist "C:\$WinREAgent" (
    rmdir /s /q "C:\$WinREAgent"
    echo Successfully deleted.
) else (
    echo Not found.
)
