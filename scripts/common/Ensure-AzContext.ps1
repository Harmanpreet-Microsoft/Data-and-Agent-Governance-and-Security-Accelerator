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
    Write-Warning "Default Azure login failed due to WAM; retrying with device authentication."
    $connectParams['UseDeviceAuthentication'] = $true
    Connect-AzAccount @connectParams | Out-Null
  }
  Select-AzSubscription -SubscriptionId $SubscriptionId | Out-Null
}
