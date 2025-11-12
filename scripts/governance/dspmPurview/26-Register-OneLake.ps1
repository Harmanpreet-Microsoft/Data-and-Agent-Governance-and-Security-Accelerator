# Filename: 26-Register-OneLake.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath,[Parameter(Mandatory=$true)][string]$OneLakeName,[Parameter(Mandatory=$true)][string]$OneLakeResourceId)
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
Import-Module Az.Accounts -ErrorAction Stop
Connect-AzAccount -Tenant $spec.tenantId | Out-Null
function Get-PvToken { (Get-AzAccessToken -ResourceUrl "https://purview.azure.net").Token }
function PvInvoke([string]$m,[string]$p,[object]$b){ $u="https://$($spec.purviewAccount).purview.azure.com$p"; $h=@{Authorization="Bearer $(Get-PvToken)";"Content-Type"="application/json"}; $j=if($b){$b|ConvertTo-Json -Depth 20}else{$null}; Invoke-RestMethod -Method $m -Uri $u -Headers $h -Body $j }
$path="/scan/datasources/$OneLakeName?api-version=2024-05-01-preview"
$body=@{ kind="FabricOneLake"; properties=@{ resourceId=$OneLakeResourceId; collection=@{ type="CollectionReference"; referenceName=$spec.purviewAccount } } }
PvInvoke 'PUT' $path $body | Out-Null
Write-Host "Registered OneLake root $OneLakeName" -ForegroundColor Green
