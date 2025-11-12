# AI Governance and Security Accelerator

This accelerator knits together Microsoft 365, Microsoft Purview, Microsoft Defender for Cloud, Azure AI Foundry, and ChatGPT Enterprise so AI solutions inherit the same governance and security posture as the rest of the enterprise. All automation is spec driven: one JSON contract (`spec.dspm.json`) feeds atomic PowerShell modules that provision cloud resources, turn on compliance controls, and light up monitoring across tenants.

- **Purview DSPM for AI** discovers, classifies, and protects data used by AI workloads in Microsoft 365, Fabric, OneLake, and connected Azure services.
- **Defender for AI** enables threat detection (prompt injection, jailbreak, exfiltration) and routes evidence into SIEM or Purview.
- **Azure AI Foundry + ChatGPT Enterprise** gain Content Safety policies, audit trails, and resource tagging so every prompt, response, and deployment can be governed.

---

## How the story comes together

1. **Author the spec** – capture tenant, subscriptions, Purview account, Azure AI assets, data sources, and compliance intent in `spec.dspm.json`.
2. **Run atomic modules** – invoke only the scripts you need (or call `run.ps1` with tags) to ensure prerequisites, enable compliance services, create policies, and register data sources.
3. **Validate posture** – use the verification modules to confirm Defender plans, audit ingestion, and Purview policy status, then hand the spec to ops for day-two governance.

---

## Capabilities at a glance

- **Purview Data Security Posture Management (DSPM) for AI**: register storage, SQL, OneLake, and Fabric workspaces, trigger Purview DSPM for AI scans, and apply sensitivity labels, DLP policies, and retention rules so AI workloads (Azure AI Foundry and ChatGPT Enterprise) inherit Microsoft Purview’s DSPM controls.
- **Security posture**: assign Azure Policies, enable Defender for Cloud plans, and ship diagnostics to Log Analytics for continuous monitoring of AI endpoints.
- **Compliance evidence**: subscribe to the Management Activity API, export audit logs, and push transcripts into storage or Fabric for downstream analytics.
- **Application guardrails**: configure Content Safety blocklists, tag Azure resources with compliance metadata, and lay the groundwork for AI prompt filtering in ChatGPT Enterprise.

---

## Quick start

1. **Clone and install tooling** (PowerShell 7, Azure CLI) in your preferred shell.
2. **Generate a spec**
   ```powershell
   pwsh ./scripts/governance/00-New-DspmSpec.ps1 -OutFile ./spec.dspm.json
   ```
3. **Fill in parameters** for tenant, subscriptions, Purview account, data sources, AI Foundry project, Key Vault, and Log Analytics once—derived resource IDs are calculated automatically.
4. **Execute the modules** (examples shown; run from the repo root):
   ```powershell
   # Azure foundation and Purview
   pwsh ./scripts/governance/01-Ensure-ResourceGroup.ps1 -SpecPath ./spec.dspm.json
   pwsh ./scripts/governance/dspmPurview/02-Ensure-PurviewAccount.ps1 -SpecPath ./spec.dspm.json

   # Compliance backbone
   pwsh ./scripts/exchangeOnline/10-Connect-Compliance.ps1
   pwsh ./scripts/exchangeOnline/11-Enable-UnifiedAudit.ps1

   # Policies, scans, and governance
   pwsh ./scripts/governance/dspmPurview/12-Create-DlpPolicy.ps1 -SpecPath ./spec.dspm.json
   pwsh ./scripts/governance/dspmPurview/03-Register-DataSource.ps1 -SpecPath ./spec.dspm.json
   pwsh ./scripts/governance/dspmPurview/04-Run-Scan.ps1 -SpecPath ./spec.dspm.json

   # AI security posture
   pwsh ./scripts/defender/defenderForAI/06-Enable-DefenderPlans.ps1 -SpecPath ./spec.dspm.json
   pwsh ./scripts/defender/defenderForAI/07-Enable-Diagnostics.ps1 -SpecPath ./spec.dspm.json

   # Foundry and Content Safety
   pwsh ./scripts/governance/dspmPurview/30-Foundry-RegisterResources.ps1 -SpecPath ./spec.dspm.json
   pwsh ./scripts/governance/dspmPurview/31-Foundry-ConfigureContentSafety.ps1 -SpecPath ./spec.dspm.json

   # Optional orchestrator (filters by tag)
   pwsh ./run.ps1 -Tags dspm,defender,foundry -SpecPath ./spec.dspm.json
   ```
5. **Review dashboards** in Purview and Defender, then export evidence with `17-Export-ComplianceInventory.ps1`, `21-Export-Audit.ps1`, and `34-Validate-Posture.ps1`.

---

## Component guides

- `scripts/governance/README.md` – Microsoft Purview DSPM automation cookbook (policies, scans, audit exports, Foundry integrations).
- `scripts/defender/README.md` – Defender for AI enablement and diagnostics.
- `docs/dspm-sales-narrative.md` – business outcome framing for stakeholders.
- `docs/payGo.md` – optional PAYG cost considerations.

---

## Architecture overview

```
M365 Compliance Boundary
  ├─ Microsoft Purview DSPM for AI
  │    ├─ Know Your Data policies (DLP, sensitivity, retention)
  │    ├─ Audit ingestion + Management Activity exports
  │    └─ Compliance role assignments
  └─ ChatGPT Enterprise + Teams, Exchange, SharePoint workloads
          │ governed via Purview policies and audit
          ▼
Azure Landing Zone
  ├─ Purview account + Log Analytics workspace
  ├─ Azure AI Foundry projects (tagged, content safety enabled)
  ├─ Azure OpenAI, Cognitive Services, Fabric, OneLake
  └─ Defender for Cloud plans + diagnostics
          │ telemetry and governance metadata flow
          ▼
Operations & Monitoring
  ├─ Spec-driven automation (PowerShell modules)
  ├─ Audit exports to Storage or Fabric Lakehouse
  └─ Posture validation scripts for day-two operations
```

---

## Script families

| Folder | Purpose | Highlights |
|--------|---------|------------|
| `scripts/governance` | Spec management, Purview account bootstrap, policy creation, audit exports, Foundry integration | `00-New-DspmSpec.ps1`, `02-Ensure-PurviewAccount.ps1`, `12-Create-DlpPolicy.ps1`, `30-Foundry-RegisterResources.ps1` |
| `scripts/defender/defenderForAI` | Enable Defender for Cloud AI plans, diagnostics, and integrations | `06-Enable-DefenderPlans.ps1`, `07-Enable-Diagnostics.ps1` |
| `scripts/exchangeOnline` | Security and Compliance PowerShell prerequisites | `10-Connect-Compliance.ps1`, `11-Enable-UnifiedAudit.ps1` |

Each script is idempotent and checks for prerequisites before applying changes. Combine them in CI, during `azd up`, or as one-off remediation tools.

---

## Prerequisites

- PowerShell 7 and Azure CLI authenticated to the target subscriptions.
- Microsoft 365 E5 (or E5 compliance) license assigned to an operator with Compliance Administrator and Purview Data Source Administrator rights.
- Exchange Online Management module installed on a workstation capable of satisfying MFA for audit enablement steps.
- Azure RBAC permissions: Contributor on the subscription that hosts Purview, AI Foundry, and Defender resources.

---

## Next steps

1. Populate `spec.dspm.json` and commit it to source control with environment-specific secrets stored in Key Vault.
2. Wire the atomic modules into your CI/CD or Azure Developer CLI pipeline by calling `run.ps1` with the appropriate tags.
3. Extend the stubs (`15-Create-SensitiveInfoType-Stub.ps1`, `23-Ship-AuditToFabricLakehouse-Stub.ps1`, `32-Foundry-GenerateBindings-Stub.ps1`) to meet organization-specific requirements.

With the spec as the contract, the accelerator keeps Microsoft 365 compliance, Defender telemetry, and Azure AI workloads aligned so AI apps stay governed from prompt to production.
