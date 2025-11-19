# AI Governance & Security FAQ

## When should this automation run relative to Copilot, Azure AI Foundry, or ChatGPT Enterprise onboarding?
Run it on **Day 0**, before end-user AI workloads are deployed. Stage the scripts so Purview DSPM for AI and unified audit are enabled first, then follow immediately with Defender for AI and Foundry tagging. That guarantees telemetry and governance data flow as soon as AI apps launch.

## Why does Purview DSPM for AI need to live on the same subscription as Defender for AI?
The Defender toggle **Enable data security for AI interactions** only streams prompt evidence to the Purview account that sits in the same subscription. If they differ, Purview’s DSPM dashboards never receive the Foundry telemetry.

## How can I run the scripts in stages?
Use `run.ps1 -Tags foundation,dspm` for the Purview/audit/policy modules, then `run.ps1 -Tags defender,foundry` for Defender plans and Foundry integrations. Each underlying PowerShell script is idempotent and can also be invoked individually for even finer control.

## Which steps remain manual?
Microsoft has not published APIs for the Defender portal toggles ("Enable data security for AI interactions" and "Enable suspicious prompt evidence"). After the scripts run, you must flip those switches **in the portal**, then rerun the verification script to confirm the state.

## Can I test the Defender scripts by toggling settings off and rerunning them?
Yes—but rerunning the PowerShell will only detect that the portal toggle is off and remind you to re-enable it. It cannot flip the switch back on; do that manually in Defender for Cloud and re-run the validation script for confirmation.

## Do the scripts create DLP policies automatically?
Yes. `scripts/governance/dspmPurview/12-Create-DlpPolicy.ps1` uses Exchange Online PowerShell (similar to `New-DlpComplianceRule`) and only requires Purview Audit to be enabled plus Compliance Administrator-level permissions.

## Why does Unified Audit still show disabled even after the scripts run?
- `11-Enable-UnifiedAudit.ps1` calls `Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true`, but Exchange ignores the change unless the operator holds a high-privilege role such as **Compliance Administrator**, **Organization Management**, or **Audit Admin**.
- When the cmdlet lacks permissions, it returns "The command completed successfully but no settings have been modified." That’s your cue to rerun the m365 tag with an appropriately privileged account or flip the toggle manually in the Purview/Microsoft 365 Compliance portal.
- Managed identities/UAMIs cannot satisfy these M365 roles today, so keep using an interactive account (or certificate-based auth) that meets the compliance requirements.

## What does enabling Unified Audit actually do, and why is it mandatory?
- Unified audit logging turns on the Microsoft 365-wide pipeline that aggregates events from Exchange Online, SharePoint/OneDrive, Teams, Entra ID, Power BI, etc., into the central Purview audit log.
- Without it, workloads either don’t emit audit events at all or keep them locked in per-service logs, so KYD, DLP, Insider Risk, eDiscovery, and Communication Compliance have nothing to reference.
- Once enabled, the Purview compliance portal (**https://compliance.microsoft.com** → **Audit**) can search across all workloads with one query, and downstream APIs (Management Activity, Office 365 Management API, Purview Audit (Premium), scripts `21-Export-Audit.ps1` / `22-Ship-AuditToStorage.ps1`) can stream those events to SIEMs, storage, or Fabric Lakehouse.
- It’s the foundation for Know Your Data: the `m365` tag publishes DLP/labels/retention, but without Unified Audit you can’t prove “user X sent prompt Y,” so auditors will reject the evidence package.
- Azure diagnostics for Foundry/OpenAI resources (wired up via `07-Enable-Diagnostics.ps1`) complement Unified Audit by capturing platform logs in Log Analytics; together they provide both Microsoft 365 and Azure telemetry for prompts, responses, and control-plane changes.

## Why are there two `logAnalyticsWorkspaceId` fields in the spec?
- The top-level `logAnalyticsWorkspaceId` (near the subscription/resourceGroup fields) is the “general purpose” workspace. Purview scans, tagging diagnostics, and other scripts wire telemetry here if they need a workspace and you don’t override it elsewhere.
- `defenderForAI.logAnalyticsWorkspaceId` lives under the `defenderForAI` block because the Defender diagnostics script (`07-Enable-Diagnostics.ps1`) can push logs to a different workspace than the rest of the automation. Leave it blank to fall back to the top-level ID, or supply a dedicated Defender workspace if your security team requires isolation.
- Both fields exist so you can either reuse a single workspace or split Defender telemetry from the broader operations log stream without editing the scripts.

## Why does the spec have both `aiFoundry` and `foundry.resources` (and two Content Safety blocks)?
- `aiFoundry` is the single “anchor” Azure AI Foundry project that scripts such as `30-Foundry-RegisterResources.ps1` expect. It provides one canonical project name/resourceId even if you only manage a single workspace.
- `foundry.resources` is an array so you can tag/monitor multiple Cognitive Services or AI Foundry workloads. Each entry feeds `25-Tag-ResourcesFromSpec.ps1`, `31-Foundry-ConfigureContentSafety.ps1`, and similar automation. If you only have one project, you’ll see the same resource repeated just so the array isn’t empty.
- `foundry.contentSafety` contains the Content Safety configuration that should be applied to those Foundry-linked resources (endpoint, Key Vault secret, blocklists, severity threshold).
- The top-level `contentSafety` section is for standalone Content Safety deployments outside Foundry—for example, when you attach Content Safety to Azure OpenAI directly. Different scripts reference each block, so both remain even if some fields are empty.

## Why do I need to add every Foundry project to the spec if Purview already shows it?
- Purview discovers Azure AI Foundry accounts on its own once Defender for Cloud plans are enabled, so new workspaces appear in the DSPM blades even if you never rerun the automation.
- The scripts only touch resources listed in `spec.local.json` (`foundry.resources[]` plus the anchor `aiFoundry`). If a workspace is missing there, rerunning `run.ps1` will skip it entirely.
- Adding the resource name/ID unlocks the downstream automation:
	- `25-Tag-ResourcesFromSpec.ps1` applies the governance tags defined in the spec.
	- `30-Foundry-RegisterResources.ps1` registers the project so DSPM recommendations stay in sync with the rest of your estate.
	- `31-Foundry-ConfigureContentSafety.ps1` pushes the configured blocklists, allow lists, and severity threshold.
	- `07-Enable-Diagnostics.ps1` only enables diagnostics on the resource IDs it knows, so omitting the workspace means no Defender log stream.
- Bottom line: Purview can display any discovered Foundry account, but listing it in the spec is what ties it into tagging, Content Safety configuration, diagnostics routing, and subsequent posture validation when you rerun the accelerator.

## Do I need Azure diagnostics for Foundry in addition to Unified Audit?
- Yes—Unified Audit covers Microsoft 365 endpoints (Teams, SharePoint, Exchange, KYD evidence), while Azure diagnostics capture logs from the Foundry/OpenAI resources themselves (API calls, request/response payload metadata, Content Safety enforcement).
- `07-Enable-Diagnostics.ps1` enables Diagnostic Settings on each Foundry/Cognitive Services resource listed in the spec and ships them to the specified Log Analytics workspace. Those logs power Defender for AI detections and give you platform-level visibility that Unified Audit can’t provide.
- Together they close the gap: Unified Audit proves what users did inside Microsoft 365, while Azure diagnostics prove what the AI infrastructure processed or attempted.

## Why doesn’t `30-Foundry-RegisterResources.ps1` touch Azure OpenAI accounts?

Confirming what’s happening: the only part of the accelerator that “registers a project” in Purview today is `30-Foundry-RegisterResources.ps1`, and that script only knows how to work with Azure AI Foundry projects (`…/accounts/<foundry>/projects/<project>` resource IDs). When you append an Azure OpenAI account (for example `/accounts/oai-cwydhg7zp`) to `foundry.resources[]`, the run still loops through the array, but this module deliberately ignores non-Foundry items because Purview already discovers plain Azure OpenAI accounts automatically. The end result matches what you see in the portal: the manual **Secure interactions for enterprise AI apps** toggle only surfaces for Foundry projects. As of today’s change, the script prints “Skipping non-Foundry resource” whenever it encounters an entry without the `/projects/` segment so the run log makes that behavior explicit.

## Can I run everything from azd, GitHub Actions, or another automation platform?
- **azd hooks / GitHub Actions / Azure Automation** work for Azure resource tasks (Purview account, Defender plans, policies). Use a service principal with `Contributor` or `Security Admin` rights.
- **Exchange Online & Compliance Center** tasks (audit enablement, DLP creation) still require interactive or certificate-based authentication tied to a high-privilege M365 role. They usually run from a workstation or secure automation account capable of satisfying MFA.

## What do I need to do before running `run.ps1` in a fresh shell or container?
1. **Install the Az PowerShell modules** (once per environment):
	```powershell
	Install-Module Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
	```
2. **Authenticate to Azure** before invoking the orchestrator. In containerized or SSH sessions without a GUI, use device code auth:
	```powershell
	Connect-AzAccount -Tenant '<tenant-guid>' -UseDeviceAuthentication
	```
	Follow the browser prompt to complete sign-in. If you prefer unattended execution, use a service principal instead (`Connect-AzAccount -ServicePrincipal ...`).
3. **Run the orchestrator** from the repo root once the session is authenticated:
	```powershell
	./run.ps1 -Tags dspm defender -SpecPath ./spec.local.json   # from bash/zsh use: pwsh ./run.ps1 -Tags ...
	```
