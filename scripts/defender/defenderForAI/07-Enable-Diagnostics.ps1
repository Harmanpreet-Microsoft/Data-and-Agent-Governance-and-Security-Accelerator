# Filename: 07-Enable-Diagnostics.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$ErrorActionPreference='Stop'
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
Import-Module Az.Accounts, Az.Monitor, Az.Resources -ErrorAction Stop
Connect-AzAccount -Tenant $spec.tenantId | Out-Null; Select-AzSubscription -SubscriptionId $spec.subscriptionId | Out-Null
$law = $spec.defenderForAI.logAnalyticsWorkspaceId
if(!$law){ Write-Host "No Log Analytics workspace configured" -ForegroundColor DarkGray; exit 0 }
$cats = if($spec.defenderForAI.diagnosticCategories){$spec.defenderForAI.diagnosticCategories}else{@("AllLogs","AllMetrics")}
foreach($r in $spec.foundry.resources){
  if(!$r.diagnostics){ continue }
  $res = Get-AzResource -ResourceId $r.resourceId -ErrorAction Stop
  $name = "$($res.Name)-diag"
  if(Get-AzDiagnosticSetting -ResourceId $r.resourceId -ErrorAction SilentlyContinue | Where-Object Name -eq $name){ Write-Host "Diagnostics exists on $($res.Name)" -ForegroundColor DarkGray; continue }
  Set-AzDiagnosticSetting -Name $name -ResourceId $r.resourceId -WorkspaceId $law -Enabled $true -Category $cats | Out-Null
  Write-Host "Enabled diagnostics for $($res.Name)" -ForegroundColor Green
}
