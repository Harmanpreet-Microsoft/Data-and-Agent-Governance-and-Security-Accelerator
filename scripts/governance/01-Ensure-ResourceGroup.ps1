# Filename: 01-Ensure-ResourceGroup.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
Import-Module Az.Accounts, Az.Resources -ErrorAction Stop
Connect-AzAccount -Tenant $spec.tenantId | Out-Null
Select-AzSubscription -SubscriptionId $spec.subscriptionId | Out-Null
$rg = Get-AzResourceGroup -Name $spec.resourceGroup -ErrorAction SilentlyContinue
if (!$rg) { New-AzResourceGroup -Name $spec.resourceGroup -Location $spec.location | Out-Null; Write-Host "Created RG" -ForegroundColor Green } else { Write-Host "RG exists" -ForegroundColor DarkGray }