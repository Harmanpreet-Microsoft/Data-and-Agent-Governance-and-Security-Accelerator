# Filename: 06-Enable-DefenderPlans.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$ErrorActionPreference='Stop'
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
Import-Module Az.Accounts, Az.Security -ErrorAction Stop
Connect-AzAccount -Tenant $spec.tenantId | Out-Null
Select-AzSubscription -SubscriptionId $spec.subscriptionId | Out-Null
$plans = $spec.defenderForAI.enableDefenderForCloudPlans
if(!$plans){ Write-Host "No Defender plans in spec" -ForegroundColor DarkGray; exit 0 }
foreach($p in $plans){ Set-AzSecurityPricing -Name $p -PricingTier "Standard" | Out-Null; Write-Host "Enabled Defender plan: $p" -ForegroundColor Green }
