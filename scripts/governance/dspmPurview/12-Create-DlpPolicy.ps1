# Filename: 12-Create-DlpPolicy.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession | Out-Null
$dlpName = $spec.dlpPolicy.name; $mode = $spec.dlpPolicy.mode; $loc = $spec.dlpPolicy.locations
if(-not (Get-DlpCompliancePolicy -Identity $dlpName -ErrorAction SilentlyContinue)){
  New-DlpCompliancePolicy -Name $dlpName -Mode $mode -ExchangeLocation $loc.Exchange -SharePointLocation $loc.SharePoint -OneDriveLocation $loc.OneDrive -TeamsLocation $loc.Teams | Out-Null
  Write-Host "Created DLP policy $dlpName" -ForegroundColor Green
} else { Write-Host "DLP policy exists" -ForegroundColor DarkGray }
foreach($r in $spec.dlpPolicy.rules){
  $ruleName=$r.name
  $sit=@{Operator='And';Groups=@(@{Operator='Or';Name='Group1';Labels=@()})}
  foreach($t in $r.sensitiveInfoTypes){ $sit.Groups[0].Labels += @{Name=$t.name;Count=$t.count;ConfidenceLevel=$t.confidence} }
  if(-not (Get-DlpComplianceRule -Policy $dlpName -ErrorAction SilentlyContinue | Where-Object Name -eq $ruleName)){
    New-DlpComplianceRule -Name $ruleName -Policy $dlpName -ContentContainsSensitiveInformation $sit -BlockAccess:([bool]$r.blockAccess) -UserNotification:([bool]$r.notifyUser) -NotifyUserAction Blocked | Out-Null
    Write-Host "Created DLP rule $ruleName" -ForegroundColor Green
  } else { Write-Host "DLP rule exists: $ruleName" -ForegroundColor DarkGray }
}
