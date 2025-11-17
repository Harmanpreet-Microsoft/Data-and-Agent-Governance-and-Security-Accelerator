# Filename: 34-Validate-Posture.ps1
param(
  [Parameter(Mandatory=$true)][string]$SpecPath,
  [string]$UserPrincipalName
)
$UserPrincipalName = if($UserPrincipalName){ $UserPrincipalName } elseif($env:DAGA_M365_UPN){ $env:DAGA_M365_UPN } else { $null }
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
# Validate Audit
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$ippParams = @{ ShowBanner = $false }
if($UserPrincipalName){ $ippParams.UserPrincipalName = $UserPrincipalName }
Connect-IPPSSession @ippParams | Out-Null
$cfg = Get-AdminAuditLogConfig
if(-not $cfg.UnifiedAuditLogIngestionEnabled){
  Write-Warning "Unified audit ingestion disabled. Attempting to enable again..."
  Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true | Out-Null
  Start-Sleep -Seconds 5
  $cfg = Get-AdminAuditLogConfig
}
if($cfg.UnifiedAuditLogIngestionEnabled){ Write-Host "OK: Unified Audit enabled" -ForegroundColor Green } else { Write-Host "FAIL: Unified Audit disabled" -ForegroundColor Red }
# Validate Defender plans
Import-Module Az.Accounts, Az.Security -ErrorAction SilentlyContinue
$ensureContextPath = Join-Path $PSScriptRoot "..\..\common\Ensure-AzContext.ps1"
. $ensureContextPath
try{
  Ensure-AzContext -TenantId $spec.tenantId -SubscriptionId $spec.subscriptionId
  $plans = $spec.defenderForAI.enableDefenderForCloudPlans
  $planMap = @{
    "CognitiveServices" = "AI"
    "Storage" = "StorageAccounts"
    "Containers" = "Containers"
    "VirtualMachines" = "VirtualMachines"
    "SqlServers" = "SqlServers"
    "KeyVaults" = "KeyVaults"
  }
  if($plans){
    foreach($p in $plans){
      $resolved = if($planMap.ContainsKey($p)){ $planMap[$p] } else { $p }
      $s = Get-AzSecurityPricing -Name $resolved -ErrorAction SilentlyContinue
      if($s -and $s.PricingTier -eq 'Standard'){
        Write-Host "OK: Defender plan $resolved (requested '$p')" -ForegroundColor Green
      } else {
        Write-Host "WARN: Defender plan not Standard: $resolved (requested '$p')" -ForegroundColor Yellow
      }
    }
  }
} catch { Write-Host "Azure validation skipped: $($_.Exception.Message)" -ForegroundColor DarkGray }
