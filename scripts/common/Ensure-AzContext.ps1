function Ensure-AzContext {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$TenantId,
    [Parameter(Mandatory=$true)][string]$SubscriptionId
  )
  Import-Module Az.Accounts -ErrorAction Stop
  $current = Get-AzContext -ErrorAction SilentlyContinue
  if($current -and $current.Tenant.Id -eq $TenantId -and $current.Subscription.Id -eq $SubscriptionId){
    return
  }
  Disable-AzContextAutosave -Scope Process -ErrorAction SilentlyContinue | Out-Null
  $connectParams = @{
    Tenant       = $TenantId
    Subscription = $SubscriptionId
  }

  $wamErrorPatterns = @(
    'BeforeBuildClient',
    'EnableLoginByWam'
  )

  try {
    Connect-AzAccount @connectParams | Out-Null
  } catch {
    $needsFallback = $false
    $cursor = $_.Exception
    while($cursor -and -not $needsFallback){
      foreach($pattern in $wamErrorPatterns){
        if($cursor.Message -match $pattern){
          $needsFallback = $true
          break
        }
      }
      $cursor = $cursor.InnerException
    }

    if(-not $needsFallback){ throw }
    $guidance = @()
    $guidance += "Default Azure login failed due to WAM (Workplace Account Manager) limitations."
    $guidance += "Device-code authentication is disabled for this accelerator."
    $guidance += "Run Connect-AzAccount -Tenant $TenantId -Subscription $SubscriptionId from an interactive shell with a browser,"
    $guidance += "or supply service principal credentials (Connect-AzAccount -ServicePrincipal ...)."
    $guidance += "Retry the script after establishing a valid context."
    throw ($guidance -join ' ')
  }
  Select-AzSubscription -SubscriptionId $SubscriptionId | Out-Null
}
