# Filename: 14-Create-RetentionPolicy.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession | Out-Null
foreach($p in $spec.retentionPolicies){
  $rp = Get-RetentionCompliancePolicy -Identity $p.name -ErrorAction SilentlyContinue
  if(!$rp){
    New-RetentionCompliancePolicy -Name $p.name -Enabled $true -ExchangeLocation $p.locations.Exchange -SharePointLocation $p.locations.SharePoint -OneDriveLocation $p.locations.OneDrive -TeamsChatLocation $p.locations.TeamsChat -TeamsChannelLocation $p.locations.TeamsChannel | Out-Null
    Write-Host "Created retention policy $($p.name)" -ForegroundColor Green
  } else { Write-Host "Retention policy exists: $($p.name)" -ForegroundColor DarkGray }
    foreach($r in $p.rules){
      if(-not (Get-RetentionComplianceRule -Identity $r.name -ErrorAction SilentlyContinue)){
        New-RetentionComplianceRule -Name $r.name -Policy $p.name -RetentionDuration $r.durationDays -RetentionAction $r.action | Out-Null
        Write-Host "Created retention rule $($r.name)" -ForegroundColor Green
      } else { Write-Host "Retention rule exists: $($r.name)" -ForegroundColor DarkGray }
    }
  }
