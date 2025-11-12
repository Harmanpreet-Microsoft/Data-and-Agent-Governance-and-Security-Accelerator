# Filename: 25-Tag-ResourcesFromSpec.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
Import-Module Az.Accounts, Az.Resources -ErrorAction Stop
Connect-AzAccount -Tenant $spec.tenantId | Out-Null; Select-AzSubscription -SubscriptionId $spec.subscriptionId | Out-Null
if ($spec.foundry -and $spec.foundry.resources) {
  foreach($r in $spec.foundry.resources){
    if(!$r.tags){ continue }
    $res = Get-AzResource -ResourceId $r.resourceId -ErrorAction Stop
    $merged = @{} + $res.Tags + $r.tags
    Set-AzResource -ResourceId $res.ResourceId -Tag $merged -Force | Out-Null
    Write-Host "Tagged $($res.Name)" -ForegroundColor Green
  }
} else {
  Write-Warning "Spec does not contain 'foundry.resources'. No resources tagged."
}
