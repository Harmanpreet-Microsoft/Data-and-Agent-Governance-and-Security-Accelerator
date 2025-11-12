param(
  [string]   $SpecPath = "./spec.dspm.json",
  [string[]] $Tags     = @("dspm"),
  [switch]   $DryRun,
  [switch]   $ContinueOnError
)

$ErrorActionPreference = "Stop"

# --- Tag aliases (feature flags)
$aliases = @{
  "dspm"      = @("foundation","compliance","policies","scans","audit")
  "defender"  = @("defender","diagnostics","policies")
  "foundry"   = @("foundry","diagnostics","tags","contentsafety")
  "all"       = @("foundation","compliance","policies","scans","audit","defender","diagnostics","foundry","networking","ops","tags","contentsafety")
}

# Expand high-level tags to concrete tags
$expanded = New-Object System.Collections.Generic.HashSet[string]
foreach ($t in $Tags) {
  if ($aliases.ContainsKey($t)) { $aliases[$t] | ForEach-Object { $expanded.Add($_) | Out-Null } }
  else                           { $expanded.Add($t) | Out-Null }
}

# --- Plan: ordered steps with tags & spec requirements
$plan = @(
  @{Order=  5; File="00-New-DspmSpec.ps1";           Tags=@("ops");                      NeedsSpec=$false; Args=@("-OutFile",$SpecPath)}
  @{Order= 10; File="01-Ensure-ResourceGroup.ps1";   Tags=@("foundation","dspm");        NeedsSpec=$true }
  @{Order= 20; File="02-Ensure-PurviewAccount.ps1";  Tags=@("foundation","dspm");        NeedsSpec=$true }
  @{Order= 30; File="10-Connect-Compliance.ps1";     Tags=@("compliance","dspm");        NeedsSpec=$false}
  @{Order= 40; File="11-Enable-UnifiedAudit.ps1";    Tags=@("audit","dspm","compliance");NeedsSpec=$false}
  @{Order= 50; File="12-Create-DlpPolicy.ps1";       Tags=@("policies","dspm");          NeedsSpec=$true }
  @{Order= 60; File="13-Create-SensitivityLabel.ps1";Tags=@("policies","dspm");          NeedsSpec=$true }
  @{Order= 70; File="14-Create-RetentionPolicy.ps1"; Tags=@("policies","dspm");          NeedsSpec=$true }
  @{Order= 80; File="03-Register-DataSource.ps1";    Tags=@("scans","dspm","foundry");   NeedsSpec=$true }
  @{Order= 90; File="04-Run-Scan.ps1";               Tags=@("scans","dspm","foundry");   NeedsSpec=$true }
  @{Order=100; File="20-Subscribe-ManagementActivity.ps1"; Tags=@("audit","dspm");      NeedsSpec=$true }
  @{Order=110; File="21-Export-Audit.ps1";           Tags=@("audit","dspm");             NeedsSpec=$true }
  @{Order=120; File="05-Assign-AzurePolicies.ps1";   Tags=@("policies","dspm","defender");NeedsSpec=$true}
  @{Order=130; File="06-Enable-DefenderPlans.ps1";   Tags=@("defender");                 NeedsSpec=$true }
  @{Order=140; File="07-Enable-Diagnostics.ps1";     Tags=@("defender","diagnostics","foundry"); NeedsSpec=$true }
  @{Order=150; File="25-Tag-ResourcesFromSpec.ps1";  Tags=@("tags","foundry","dspm");    NeedsSpec=$true }
  @{Order=160; File="26-Register-OneLake.ps1";       Tags=@("scans","foundry","dspm");   NeedsSpec=$true }
  @{Order=170; File="27-Register-FabricWorkspace.ps1";Tags=@("scans","foundry","dspm");  NeedsSpec=$true }
  @{Order=180; File="28-Trigger-OneLakeScan.ps1";    Tags=@("scans","foundry","dspm");   NeedsSpec=$true }
  @{Order=190; File="29-Trigger-FabricWorkspaceScan.ps1"; Tags=@("scans","foundry","dspm"); NeedsSpec=$true }
  @{Order=200; File="30-Foundry-RegisterResources.ps1"; Tags=@("foundry","ops");         NeedsSpec=$true }
  @{Order=210; File="31-Foundry-ConfigureContentSafety.ps1"; Tags=@("foundry","contentsafety","defender"); NeedsSpec=$true }
  @{Order=220; File="08-Ensure-PrivateEndpoints.ps1";Tags=@("networking","dspm","foundry"); NeedsSpec=$true }
  @{Order=230; File="17-Export-ComplianceInventory.ps1"; Tags=@("ops","dspm");           NeedsSpec=$false}
  @{Order=240; File="33-Compliance-Report.ps1";      Tags=@("ops","dspm");               NeedsSpec=$false}
  @{Order=250; File="34-Validate-Posture.ps1";       Tags=@("ops","dspm","defender");    NeedsSpec=$true }
  # Stubs (optional steps)
  @{Order=260; File="15-Create-SensitiveInfoType-Stub.ps1";    Tags=@("policies","dspm"); NeedsSpec=$false}
  @{Order=270; File="16-Create-TrainableClassifier-Stub.ps1";  Tags=@("policies","dspm"); NeedsSpec=$false}
  @{Order=280; File="22-Ship-AuditToStorage.ps1";              Tags=@("audit","ops");     NeedsSpec=$false}
  @{Order=290; File="23-Ship-AuditToFabricLakehouse-Stub.ps1"; Tags=@("audit","foundry"); NeedsSpec=$false}
  @{Order=300; File="24-Create-BudgetAlert-Stub.ps1";          Tags=@("ops");             NeedsSpec=$false}
)

# Filter by tags
$selected = $plan.Where({
  ($_.Tags | ForEach-Object { $expanded.Contains($_) }) -contains $true
}) | Sort-Object Order

if ($selected.Count -eq 0) {
  Write-Host "No steps matched tags: $($Tags -join ', ')" -ForegroundColor Yellow
  exit 0
}

Write-Host "Running steps for tags: $($Tags -join ', ')" -ForegroundColor Cyan

foreach ($step in $selected) {
  $args = @()
  if ($step.NeedsSpec) { $args += @("-SpecPath", $SpecPath) }
  if ($step.Args)      { $args += $step.Args }

  $cmdDisplay = ".\{0} {1}" -f $step.File, ($args -join ' ')
  if ($DryRun) {
    Write-Host "[DRYRUN] $cmdDisplay" -ForegroundColor DarkGray
    continue
  }

  Write-Host "==> $cmdDisplay" -ForegroundColor Green
  try {
    & ".\$($step.File)" @args
  } catch {
    Write-Host "ERROR in $($step.File): $($_.Exception.Message)" -ForegroundColor Red
    if (-not $ContinueOnError) { throw }
  }
}
