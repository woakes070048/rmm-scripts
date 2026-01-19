$ErrorActionPreference = 'Stop'
<#
================================================================================
 SCRIPT   : Console Output Format Test                                   v1.0.0
 AUTHOR   : Limehawk.io
 DATE     : January 2026
 USAGE    : .\console_output_test.ps1
================================================================================
 FILE     : console_output_test.ps1
 DESCRIPTION : Tests Two-Line ASCII Style console output for SuperOps
--------------------------------------------------------------------------------
 CHANGELOG
--------------------------------------------------------------------------------
 2026-01-19 v1.0.0 Test Style 53 - two-line format
================================================================================
#>
Set-StrictMode -Version Latest

Write-Host ""
Write-Host "[INFO] INPUT VALIDATION"
Write-Host "=============================================================="
Write-Host "  Test Value   : OK"
Write-Host "  Environment  : Production"

Write-Host ""
Write-Host "[RUN] DOWNLOADING"
Write-Host "=============================================================="
Write-Host "  Downloading file from server..."
Write-Host "  Progress: 100%"

Write-Host ""
Write-Host "[RUN] INSTALLING"
Write-Host "=============================================================="
Write-Host "  Installing application..."
Write-Host "  Installation complete"

Write-Host ""
Write-Host "[INFO] RESULT"
Write-Host "=============================================================="
Write-Host "  Status       : Success"
Write-Host "  Files        : 3 processed"
Write-Host "  Errors       : 0"

Write-Host ""
Write-Host "[WARN] CHECK THIS"
Write-Host "=============================================================="
Write-Host "  A non-critical warning message"
Write-Host "  This does not block execution"

Write-Host ""
Write-Host "[ERROR] EXAMPLE ERROR"
Write-Host "=============================================================="
Write-Host "  This is what an error section looks like"
Write-Host "  Actual errors would exit here"

Write-Host ""
Write-Host "[OK] FINAL STATUS"
Write-Host "=============================================================="
Write-Host "  Result : SUCCESS"
Write-Host "  All operations completed"

Write-Host ""
Write-Host "[OK] SCRIPT COMPLETED"
Write-Host "=============================================================="

exit 0
