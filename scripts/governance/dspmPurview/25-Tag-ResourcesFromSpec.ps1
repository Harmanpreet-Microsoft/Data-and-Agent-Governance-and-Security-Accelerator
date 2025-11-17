# Filename: 25-Tag-ResourcesFromSpec.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
$ensureContextPath = Join-Path $PSScriptRoot "..\..\common\Ensure-AzContext.ps1"
. $ensureContextPath
Import-Module Az.Accounts, Az.Resources -ErrorAction Stop
Ensure-AzContext -TenantId $spec.tenantId -SubscriptionId $spec.subscriptionId
if ($spec.foundry -and $spec.foundry.resources) {
  foreach($r in $spec.foundry.resources){
    if(!$r.tags){ continue }
    $res = Get-AzResource -ResourceId $r.resourceId -ErrorAction Stop
    $merged = @{}
    if($res.Tags -is [Collections.IDictionary]){ $merged += $res.Tags }
    if($r.tags -is [Collections.IDictionary]){ $merged += $r.tags }
    Set-AzResource -ResourceId $res.ResourceId -Tag $merged -Force | Out-Null
    Write-Host "Tagged $($res.Name)" -ForegroundColor Green
  }
} else {
  Write-Warning "Spec does not contain 'foundry.resources'. No resources tagged."
}
