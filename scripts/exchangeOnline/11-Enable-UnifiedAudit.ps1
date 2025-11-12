# Filename: 11-Enable-UnifiedAudit.ps1
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession | Out-Null
$cfg = Get-AdminAuditLogConfig
if(-not $cfg.UnifiedAuditLogIngestionEnabled){ Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true; Write-Host "Unified Audit enabled" -ForegroundColor Green } else { Write-Host "Unified Audit already enabled" -ForegroundColor DarkGray }