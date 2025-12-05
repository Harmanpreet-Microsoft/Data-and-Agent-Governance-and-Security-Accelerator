# Deployment Guide

Follow this guide to deploy the Data Agent Governance and Security Accelerator (DAGA) into your Azure subscription using the Azure Developer CLI (azd).

> **Tooling requirements**
>
> - Azure Developer CLI (azd) **1.9.0 or later**
> - Azure CLI **2.58.0 or later**
> - PowerShell **7.x**
> - Az PowerShell modules (`Install-Module Az -Scope CurrentUser -Force`)
> - Exchange Online Management module (required when running the `m365` tag)
>
> Use `azd version`, `az --version`, and `pwsh --version` to verify the versions installed on your machine.

---

## 1. Clone and open the repository

```powershell
cd <working-directory>
git clone https://github.com/microsoft/Data-Agent-Governance-and-Security-Accelerator.git
git checkout readme-update-120225
```

Open the folder in VS Code, Codespaces, or a devcontainer if you prefer a managed environment.

---

## 2. Sign in to Azure

All provisioning relies on the credentials already cached by the Azure CLI and Az PowerShell. Run the following commands **in the same terminal** you will use for `azd up`:

```powershell
az login
azd auth login
Connect-AzAccount -Tenant <tenantId> -Subscription <subscriptionId>
Set-AzContext -Subscription <subscriptionId>
Get-AzContext    # confirm the tenant/subscription match your spec
```

Replace the placeholders with the values at the top of your `spec.local.json`. If you are using a service principal, pass `-ServicePrincipal` parameters to `Connect-AzAccount` instead.

---

## 3. Prepare the spec

1. Generate or refresh the schema:
   ```powershell
   pwsh ./scripts/governance/00-New-DspmSpec.ps1 -OutFile ./spec.dspm.template.json
   ```
2. Create your local copy and keep it out of source control:
   ```powershell
   Copy-Item ./spec.dspm.template.json ./spec.local.json
   ```
3. Populate the JSON with tenant IDs, Purview account info, Foundry projects, Defender plans, and optional `activityExport` settings. Use Key Vault references for secrets whenever possible.

---

## 4. Configure azd parameters (optional)

`infra/main.bicepparam` mirrors hook inputs. Update these values if you want `azd` to pass different tags or Microsoft 365 options to `run.ps1`:

```bicep-params
param dagaSpecPath = './spec.local.json'
param dagaTags = [
  'foundation'
  'dspm'
  'defender'
  'foundry'
]
param dagaConnectM365 = true
param dagaM365UserPrincipalName = 'admin@contoso.onmicrosoft.com'
```

Environment variables (`DAGA_SPEC_PATH`, `DAGA_POSTPROVISION_TAGS`, etc.) override the parameter file if you need temporary changes.

---

## 5. Deploy with `azd up`

```powershell
azd up
```

- The Bicep template is a no-op placeholder; provisioning time is dominated by the post-provision PowerShell hook.
- The hook imports your Azure CLI tokens, sets strict mode, and runs `run.ps1` with the tags defined earlier.
- Expect interactive prompts only if the Microsoft 365 steps need Exchange Online authentication.

If you are running outside of azd, you can execute the same automation directly:

```powershell
pwsh ./run.ps1 -Tags foundation,dspm,defender,foundry -SpecPath ./spec.local.json
```

Run `./run.ps1 -Tags m365 -ConnectM365 -M365UserPrincipalName <upn>` from a workstation that can satisfy MFA to publish the Secure Interactions / KYD policies.

---

## 6. Post-deployment actions

1. **Purview portal toggles** – enable *Secure interactions for enterprise AI apps* in the Purview portal (Data Security Posture Management for AI > Recommendations).
2. **Role assignments** – ensure the operator account has the Audit Reader (or Compliance Administrator) role before running the audit export scripts.
3. **Evidence collection** – rerun `./scripts/governance/dspmPurview/17-Export-ComplianceInventory.ps1` when you are ready to archive posture evidence.
4. **Cost management** – review `docs/payGo.md` and set budget alerts or run `azd down` when the environment is no longer required.

---

## 7. Next steps

- Customize the spec for additional Foundry projects or Fabric workspaces.
- Integrate the accelerator into CI/CD by invoking `run.ps1` from GitHub Actions or Azure DevOps.
- Extend the stub scripts (for example, `15-Create-SensitiveInfoType-Stub.ps1`) with organization-specific logic.

Refer to the [Troubleshooting Guide](./TroubleshootingGuide.md) if `azd up` surfaces authentication or permission errors.
