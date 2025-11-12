# Filename: 04-Run-Scan.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
Import-Module Az.Accounts -ErrorAction Stop
Connect-AzAccount -Tenant $spec.tenantId | Out-Null
function Get-PvToken { (Get-AzAccessToken -ResourceUrl "https://purview.azure.net").Token }
function PvInvoke([string]$m,[string]$p,[object]$b) {
  $u = "https://$($spec.purviewAccount).purview.azure.com$p"
  $h = @{ Authorization="Bearer $(Get-PvToken)"; "Content-Type"="application/json" }
  $j = if($b){$b|ConvertTo-Json -Depth 20}else{$null}
  Invoke-RestMethod -Method $m -Uri $u -Headers $h -Body $j
}
foreach($s in $spec.scans){
  $p = "/scan/datasources/$($s.dataSource)/scans/$($s.name)?api-version=2024-05-01-preview"
  $b = @{ properties=@{ scanRulesetType=$s.rulesetType; scanRulesetName=$s.rulesetName; incrementalScanStartTime=(Get-Date).ToUniversalTime().ToString('o'); collection=@{ type='CollectionReference'; referenceName=$spec.purviewAccount } } }
  PvInvoke 'PUT' $p $b | Out-Null
  PvInvoke 'POST' "/scan/datasources/$($s.dataSource)/scans/$($s.name)/run?api-version=2024-05-01-preview" $null | Out-Null
  Write-Host "Triggered scan $($s.name) on $($s.dataSource)" -ForegroundColor Green
}