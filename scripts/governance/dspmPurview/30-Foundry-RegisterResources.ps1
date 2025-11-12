# Filename: 30-Foundry-RegisterResources.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$ErrorActionPreference='Stop'
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
Import-Module Az.Accounts, Az.Resources -ErrorAction Stop
Connect-AzAccount -Tenant $spec.tenantId | Out-Null; Select-AzSubscription -SubscriptionId $spec.subscriptionId | Out-Null
if(!$spec.foundry.resources){ Write-Host "No foundry.resources"; exit 0 }
foreach($r in $spec.foundry.resources){
  $res = Get-AzResource -ResourceId $r.resourceId -ErrorAction Stop
  Write-Host "Found resource: $($res.ResourceId)" -ForegroundColor Cyan
  if($r.tags){ $merged = @{} + $res.Tags + $r.tags; Set-AzResource -ResourceId $res.ResourceId -Tag $merged -Force | Out-Null; Write-Host "Applied tags to $($res.Name)" -ForegroundColor Green }
}
