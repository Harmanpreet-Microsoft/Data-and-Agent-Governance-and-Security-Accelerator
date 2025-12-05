# Troubleshooting Guide

Use this guide to resolve common issues when running the Data Agent Governance and Security Accelerator.

## 1. Post-provision hook re-prompts for login
- **Symptoms:** `Connect-AzAccount` opens a browser during `azd up` or fails with `InteractiveBrowserCredential` errors.
- **Fix:** Ensure you ran `az login`, `azd auth login`, `Connect-AzAccount -Tenant ... -Subscription ...`, and `Set-AzContext` in the same terminal before invoking `azd up`. The hook only reuses existing contexts.

## 2. Management Activity API returns 401
- **Symptoms:** `20-Subscribe-ManagementActivity.ps1` or `21-Export-Audit.ps1` fails with `Authorization has been denied for this request`.
- **Fix:**
  1. Assign the operator to the **Audit Reader** or **Compliance Administrator** role under Microsoft Purview permissions.
  2. Confirm the user has an Exchange Online / Microsoft 365 E5 license and that auditing is enabled (`Get-AdminAuditLogConfig`).
  3. Run `Disconnect-AzAccount`, `az logout`, and sign in again so new tokens include the `ActivityFeed.Read` role.

## 3. Missing spec blocks (activityExport, azurePolicies)
- **Symptoms:** Scripts complain that `contentTypes` or `azurePolicies` cannot be found.
- **Fix:**
  - Update to the latest main branch (scripts now skip gracefully when those blocks are missing), or
  - Reintroduce the section into `spec.local.json` using `spec.dspm.template.json` as a reference.

## 4. Content Safety endpoint skipped
- **Symptoms:** `31-Foundry-ConfigureContentSafety.ps1` logs `foundry.contentSafety.endpoint not provided`.
- **Fix:** Provide the Content Safety endpoint and either a Key Vault secret reference or confirm Entra ID access works for the AI subscription. This message is informational; populate the block only when you are ready to configure Content Safety.

## 5. `azd up` fails after changes to README or docs
- **Symptoms:** `postprovision.ps1` fails with backtick or markdown tokens in the error message.
- **Fix:** Ensure PowerShell scripts do not contain stray Markdown fences (````` ```). Run `git status` to confirm only README/docs changed.

## 6. Defender for AI diagnostics not flowing
- **Symptoms:** No logs appear in Log Analytics after running `07-Enable-Diagnostics.ps1`.
- **Fix:**
  - Verify the `defenderForAI.logAnalyticsWorkspaceId` value in the spec points to an existing workspace with the correct permissions.
  - Confirm the Defender plan (`enableDefenderForCloudPlans`) includes `CognitiveServices` and that Defender for Cloud is enabled in the subscription.

If your issue is not listed here, open a new issue in the repository with the failing script name, the exact error text, and the relevant snippet from `spec.local.json` (redacting secrets).
