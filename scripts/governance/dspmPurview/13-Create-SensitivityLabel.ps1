# Filename: 13-Create-SensitivityLabel.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-IPPSSession | Out-Null
foreach($l in $spec.labels){
  $label = Get-Label -Identity $l.name -ErrorAction SilentlyContinue
  if(!$label){ $label = New-Label -Name $l.name -ContentType File,Email -EncryptionEnabled:([bool]$l.encryptionEnabled); Write-Host "Created label $($l.name)" -ForegroundColor Green } else { Write-Host "Label exists: $($l.name)" -ForegroundColor DarkGray }
  $pp=$l.publishPolicyName
  if(-not (Get-LabelPolicy -Identity $pp -ErrorAction SilentlyContinue)){
    New-LabelPolicy -Name $pp -Labels $l.name -ExchangeLocation $l.publishScopes.Exchange -SharePointLocation $l.publishScopes.SharePoint -OneDriveLocation $l.publishScopes.OneDrive | Out-Null
    Write-Host "Published label via $pp" -ForegroundColor Green
  } else { Write-Host "Publish policy exists: $pp" -ForegroundColor DarkGray }
}
