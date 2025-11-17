# Filename: 02-Ensure-PurviewAccount.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
$ensureContextPath = Join-Path $PSScriptRoot "..\..\common\Ensure-AzContext.ps1"
. $ensureContextPath
Import-Module Az.Accounts, Az.Purview -ErrorAction Stop
Ensure-AzContext -TenantId $spec.tenantId -SubscriptionId $spec.subscriptionId
$pv = Get-AzPurviewAccount -Name $spec.purviewAccount -ResourceGroupName $spec.resourceGroup -ErrorAction SilentlyContinue
if (!$pv) { New-AzPurviewAccount -Name $spec.purviewAccount -ResourceGroupName $spec.resourceGroup -Location $spec.location | Out-Null; Write-Host "Created Purview account" -ForegroundColor Green } else { Write-Host "Purview account exists" -ForegroundColor DarkGray }