# Filename: 05-Assign-AzurePolicies.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$ErrorActionPreference='Stop'
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
Import-Module Az.Accounts, Az.Resources -ErrorAction Stop
Connect-AzAccount -Tenant $spec.tenantId | Out-Null
Select-AzSubscription -SubscriptionId $spec.subscriptionId | Out-Null
if(!$spec.azurePolicies){ Write-Host "No azurePolicies in spec" -ForegroundColor DarkGray; exit 0 }
function Resolve-DefId([string]$display,[string]$id){ if($id){return $id}; (Get-AzPolicyDefinition -Builtin | Where-Object {$_.Properties.DisplayName -eq $display} | Select-Object -First 1).PolicyDefinitionId }
foreach($p in $spec.azurePolicies){
  $scope = if($p.scope -eq 'subscription') { "/subscriptions/$($spec.subscriptionId)" } else { "/subscriptions/$($spec.subscriptionId)/resourceGroups/$($spec.resourceGroup)" }
  $defId = Resolve-DefId $p.displayName $p.definitionId
  if(Get-AzPolicyAssignment -Scope $scope -ErrorAction SilentlyContinue | Where-Object Name -eq $p.name){ Write-Host "Policy $($p.name) exists" -ForegroundColor DarkGray; continue }
  New-AzPolicyAssignment -Name $p.name -DisplayName $p.displayName -PolicyDefinitionId $defId -Scope $scope -PolicyParameterObject $p.parameters | Out-Null
  Write-Host "Assigned policy $($p.displayName) at $scope" -ForegroundColor Green
