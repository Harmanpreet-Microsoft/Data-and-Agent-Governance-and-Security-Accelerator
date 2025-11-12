# DSPM + Defender for AI Narrative Guide

Use this supplement when briefing sellers, technical specialists, or customer champions. Each section pairs the **what**, **why**, and **objection handling** for every automation step so teams can frame the value in plain language.

---

## 1. Seed the Environment (Parameter File + `azd` hooks)
- **What happens**: We load Purview and Azure AI identifiers from `infra/main.bicepparam` and push them into the `azd` environment before any script runs.
- **Why it matters**: Customers often split Purview and AI into different subscriptions. Parameterizing the IDs up front proves we can handle cross-subscription governance without redeploying infrastructure.
- **Objections to expect**
  - *“We already track IDs elsewhere.”* → The helper script simply mirrors customer reality; no redeployment required.
  - *“Is this provisioning resources?”* → No. The Bicep template is a placeholder; the value is in the governance configuration.

---

## 2. Enable Microsoft Purview Audit & DSPM Hub
- **What happens**: `enable_purview_dspm.ps1` verifies licensing, checks Azure authentication, and walks admins through turning on audit and DSPM for AI.
- **Why it matters**: Audit is the compliance safety net. Without it, there is no ledger showing who prompted the model or accessed results. The script proves prerequisites are in place before we continue.
- **Objection handling**
  - *“We thought audit was on by default.”* → Audit is enabled for many tenants, but DSPM for AI analytics is still a manual toggle. The script confirms status and catches surprises early.
  - *“Do we need E5?”* → Yes. Microsoft’s own documentation (link in main guide) states DSPM for AI rides on E5 or E5 Compliance licensing.

---

## 3. Create the Know Your Data (KYD) Collection Policy
- **What happens**: `create_dspm_policies.ps1` loads the Exchange Online PowerShell module, connects to the compliance endpoint, and creates the “Secure interactions from enterprise apps” policy.
- **Why it matters**: DSPM does not store prompts on its own. Microsoft explicitly says captured prompts/responses live in the user’s mailbox so they inherit retention, eDiscovery, and Communication Compliance. The Exchange Online cmdlets are the bridge that turns on that capture.
- **Objection handling**
  - *“Why do we need Exchange Online?”* → Because the mailbox is the evidence repository. Without this, there is no durable record of AI usage and compliance teams cannot search or retain it.
  - *“Can the script install the module for me?”* → `Install-Module` requires policy approval and sometimes admin elevation. We surface the command so operators can run it once with the right governance guardrails.
  - *“Why did MFA break in VS Code?”* → The compliance login redirects to `localhost`. In a dev container that callback fails, so admins must complete one sign-in from a host PowerShell session with interactive browser access (or use certificate-based auth).
  - *“What do admins actually run?”* → We give them the exact host-side sequence: force TLS 1.2, set execution policy to Process Bypass, install/import ExchangeOnlineManagement, then call `Connect-IPPSSession` so MFA completes in their default browser before rerunning automation.
  - *“How do we keep automation happy afterward?”* → Set `AZD_SKIP_EXCHANGE_CONNECTION=true` in the container so the orchestration skips the Exchange login check once the KYD policy is created manually.

---

## 4. Portal Policies (Communication Compliance & Insider Risk)
- **What happens**: The script prints a checklist, then admins finish the two remaining policies in the Purview portal.
- **Why it matters**: These policies are still UI-only in preview. Calling them out prevents a false sense of “automation done” and keeps security/compliance owners in the loop.
- **Objection handling**
  - *“Why can’t you script everything?”* → Microsoft has not released APIs for those previews yet. We give precise navigation links and language so admins can execute quickly.
  - *“Do we really need both policies?”* → Yes—Communication Compliance catches inappropriate use, and Insider Risk flags exfiltration or prompt injection patterns. They feed the DSPM dashboards customers expect to see.

---

## 5. Connect DSPM to Azure AI Foundry
- **What happens**: `connect_dspm_to_ai_foundry.ps1` enumerates AI workspaces, records IDs, and tells admins how to toggle the integration inside Azure AI Foundry (with a Learn link for the latest UI).
- **Why it matters**: This is the handshake between runtime AI projects and governance. Without it, DSPM sees zero interactions and the customer assumes the feature “doesn’t work.”
- **Objection handling**
  - *“The UI moved; your script failed.”* → We point to Microsoft’s doc so teams always have the authoritative navigation path, even if the portal changes.
  - *“Why not auto-enable?”* → Foundry provides the switch so data owners can opt individual projects in. We respect that boundary and use automation to highlight what remains manual.

---

## 6. Verify DSPM Configuration
- **What happens**: `verify_dspm_configuration.ps1` replays the critical checks (KYD policy, audit flag, compliance connectivity) and summarizes the state.
- **Why it matters**: Customers learn exactly what succeeded, what is pending, and where to look in the Purview portal. This is the “trust but verify” moment for security owners.
- **Objection handling**
  - *“It still says ‘manual steps required’.”* → Correct; some preview toggles must stay manual today. The script gives the ready-to-send instructions so administrators can finish the work.

---

## 7. Defender for Cloud CSPM + Defender for AI Plans
- **What happens**: `enable_defender_for_cloud.ps1` and `enable_defender_for_ai.ps1` register providers and switch on the AI plan, reporting back which AI services are now protected.
- **Why it matters**: Defender for Cloud is where threat protection and posture scoring show up. Turning on the AI plan is the ticket to user prompt evidence, risk analytics, and correlation across data security and threat detection.
- **Objection handling**
  - *“Isn’t this just another SKU?”* → The AI plan is built into Defender for Cloud once the subscription is onboarded. No separate purchase, but it must be explicitly enabled.
  - *“What if we’re already using Defender?”* → The script simply confirms configuration and prints the existing state. There is no conflict.

---

## 8. User Prompt Evidence & Purview Integration
- **What happens**: The scripts attempt the preview APIs; if unavailable, they log the portal path to enable user prompt evidence and the Purview integration toggle.
- **Why it matters**: These previews light up the correlated dashboards in Defender and Purview. Without them, customers cannot trace malicious prompts back to the human that sent them.
- **Objection handling**
  - *“The toggle isn’t in our portal.”* → Some tenants require approval for preview features. The script output tells administrators to request access rather than wondering if automation failed.

---

## 9. Post-Run Summary & Logs
- **What happens**: `invoke-governance-automation.ps1` prints `[governance-run]` success/failure lines and saves the full transcript under `logs/governance/`.
- **Why it matters**: Operators leave the session with a snapshot they can paste into a ticket, email, or meeting notes. It is proof of work and a diagnostic starting point if something failed.
- **Objection handling**
  - *“I don’t want to sift through `azd` output.”* → The runner collects everything in one summary table and log file, so customers see exactly what passed or failed within seconds.

---

## 10. Storyboard for Sellers
Use this three-sentence elevator pitch when positioning the solution:
1. **“We wire your AI estate into Purview so every prompt lives inside the same trusted compliance boundary as email and Teams.”**
2. **“We turn on Defender for AI so threats, data security, and user-level evidence sit in one dashboard your SOC already uses.”**
3. **“We leave you with a run log, a manual checklist, and Microsoft Learn links so your admins can finish any previews Microsoft still keeps in the portal.”**

Highlight that each automation step corresponds to Microsoft guidance—nothing proprietary or black-box—and that the scripts exist to remove toil while respecting the customer’s approval gates.
