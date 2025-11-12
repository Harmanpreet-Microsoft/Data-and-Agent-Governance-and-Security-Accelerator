# Filename: 34-Validate-Posture.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
# Validate Audit
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession | Out-Null
$cfg = Get-AdminAuditLogConfig
if($cfg.UnifiedAuditLogIngestionEnabled){ Write-Host "OK: Unified Audit enabled" -ForegroundColor Green } else { Write-Host "FAIL: Unified Audit disabled" -ForegroundColor Red }
# Validate Defender plans
Import-Module Az.Accounts, Az.Security -ErrorAction SilentlyContinue
try{
  Connect-AzAccount -Tenant $spec.tenantId | Out-Null; Select-AzSubscription -SubscriptionId $spec.subscriptionId | Out-Null
  $plans = $spec.defenderForAI.enableDefenderForCloudPlans
  if($plans){ foreach($p in $plans){ $s=Get-AzSecurityPricing -Name $p -ErrorAction SilentlyContinue; if($s -and $s.PricingTier -eq 'Standard'){ Write-Host "OK: Defender plan $p" -ForegroundColor Green } else { Write-Host "WARN: Defender plan not Standard: $p" -ForegroundColor Yellow } } }
} catch { Write-Host "Azure validation skipped: $($_.Exception.Message)" -ForegroundColor DarkGray }
