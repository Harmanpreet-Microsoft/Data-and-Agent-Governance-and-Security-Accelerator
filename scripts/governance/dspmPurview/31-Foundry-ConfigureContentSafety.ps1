# Filename: 31-Foundry-ConfigureContentSafety.ps1
param([Parameter(Mandatory=$true)][string]$SpecPath)
$ErrorActionPreference='Stop'
$spec = Get-Content $SpecPath -Raw | ConvertFrom-Json
if(!$spec.foundry.contentSafety){ Write-Host "No foundry.contentSafety"; exit 0 }
Import-Module Az.Accounts, Az.KeyVault, Az.Resources -ErrorAction Stop
Connect-AzAccount -Tenant $spec.tenantId | Out-Null; Select-AzSubscription -SubscriptionId $spec.subscriptionId | Out-Null
$cs = $spec.foundry.contentSafety
$kvRes = Get-AzResource -ResourceId $cs.apiKeySecretRef.keyVaultResourceId -ErrorAction Stop
$kvName = ($kvRes.ResourceId -split "/")[-1]
$apiKey = (Get-AzKeyVaultSecret -VaultName $kvName -Name $cs.apiKeySecretRef.secretName -ErrorAction Stop).SecretValueText
$base = $cs.endpoint.TrimEnd('/')
if($cs.textBlocklists){
  foreach($bl in $cs.textBlocklists){
    $uri = "$base/contentsafety/text/blocklists/$($bl.name)?api-version=2024-02-15-preview"
    try{ Invoke-RestMethod -Method PUT -Uri $uri -Headers @{ "Ocp-Apim-Subscription-Key"=$apiKey } -ContentType "application/json" -Body (@{}|ConvertTo-Json) | Out-Null; Write-Host "Ensured blocklist: $($bl.name)" -ForegroundColor Green }catch{ Write-Host "Blocklist ensure may exist: $($_.Exception.Message)" -ForegroundColor DarkGray }
    if($bl.items -and $bl.items.Count -gt 0){
      $itemsUri = "$base/contentsafety/text/blocklists/$($bl.name)/:blockItems?api-version=2024-02-15-preview"
      $body = @{ blockItems=@() }; foreach($itm in $bl.items){ $body.blockItems += @{ description=$itm; text=$itm } }
      Invoke-RestMethod -Method POST -Uri $itemsUri -Headers @{ "Ocp-Apim-Subscription-Key"=$apiKey } -ContentType "application/json" -Body ($body|ConvertTo-Json -Depth 10) | Out-Null
      Write-Host "Added $($bl.items.Count) items to '$($bl.name)'" -ForegroundColor Green
    }
  }
}
if($cs.harmSeverityThreshold){ Write-Host "harmSeverityThreshold=$($cs.harmSeverityThreshold). Enforce in request filter." }