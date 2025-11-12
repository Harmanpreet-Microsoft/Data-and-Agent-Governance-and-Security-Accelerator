# DSPM + AI Governance Automation (Spec-Driven)

This repository contains **atomic PowerShell scripts** for automating Microsoft Purview DSPM, Defender for AI posture, and Azure AI Foundry governance. Each script is **idempotent**, **spec-driven**, and can be run independently or orchestrated via pipelines.

---

## ✅ What’s Included
- **Spec Template** (`spec.dspm.json`) capturing:
  - Azure context (tenant, subscription, RG, Purview account)
  - Data sources & scans
  - DLP policies, sensitivity labels, retention rules
  - Audit export settings
  - Defender for AI plans, diagnostics, Azure Policies
  - AI Foundry resources & Content Safety blocklists

- **Atomic Scripts**:
  - `00-New-DspmSpec.ps1` – Scaffold spec
  - `01-Ensure-ResourceGroup.ps1` – Create RG
  - `02-Ensure-PurviewAccount.ps1` – Create Purview account
  - `03-Register-DataSource.ps1` – Register data sources
  - `04-Run-Scan.ps1` – Trigger scans
  - `10-Connect-Compliance.ps1` – Connect to IPPS
  - `11-Enable-UnifiedAudit.ps1` – Enable Unified Audit Log
  - `12-Create-DlpPolicy.ps1` – Create DLP policy & rules
  - `13-Create-SensitivityLabel.ps1` – Create labels & publish
  - `14-Create-RetentionPolicy.ps1` – Create retention policies
  - `20-Subscribe-ManagementActivity.ps1` – Start audit subscriptions
  - `21-Export-Audit.ps1` – Export audit logs
  - `05-Assign-AzurePolicies.ps1` – Assign built-in Azure Policies
  - `06-Enable-DefenderPlans.ps1` – Enable Defender for Cloud plans
  - `07-Enable-Diagnostics.ps1` – Configure diagnostics to Log Analytics
  - `30-Foundry-RegisterResources.ps1` – Tag AI Foundry resources
  - `31-Foundry-ConfigureContentSafety.ps1` – Configure Content Safety blocklists

---

## ✅ Order of Operations Diagram

```mermaid
flowchart TD
    A[Start: Spec Creation]:::manual --> B[01 Ensure Resource Group]:::auto
    B --> C[02 Ensure Purview Account]:::auto
    C --> D[10 Connect Compliance PowerShell]:::auto
    D --> E[11 Enable Unified Audit Log]:::auto
    E --> F[12 Create DLP Policy & Rules]:::auto
    F --> G[13 Create Sensitivity Labels & Publish]:::auto
    G --> H[14 Create Retention Policies & Rules]:::auto
    H --> I[03 Register Data Sources]:::auto
    I --> J[04 Trigger DSPM Scans]:::auto
    J --> K[20 Subscribe Management Activity API]:::auto
    K --> L[21 Export Audit Logs]:::auto
    L --> M[05 Assign Azure Policies]:::auto
    M --> N[06 Enable Defender for Cloud Plans]:::auto
    N --> O[07 Enable Diagnostics to Log Analytics]:::auto
    O --> P[30 Tag AI Foundry Resources]:::auto
    P --> Q[31 Configure Content Safety Blocklists]:::auto
    Q --> R[End: Governance & Security Posture Complete]:::auto

    classDef auto fill:#0078D4,stroke:#004578,color:#fff;
    classDef manual fill:#FFB900,stroke:#A05A00,color:#000;

    %% Legend
    L1[Legend: Manual Step]:::manual
    L2[Legend: Automated Step]:::auto
```
## Script Inventory (Atomic Modules)

Tags enable the feature‑flag behavior in run.ps1.
Use them to run subsets like dspm, defender, foundry, scans, audit, policies, networking, ops.
| **Script** | **Step / Purpose** | **DSPM for AI Relation (Purview)** | **Primary Tags** | **Requires Spec?** |
|------------|----------------------|-------------------------------------|-------------------|----------------------|
| `00-New-DspmSpec.ps1` | Scaffold a JSON spec template | Input contract for all automation | `ops` | No |
| `01-Ensure-ResourceGroup.ps1` | Ensure Azure RG exists | Foundation for Purview account | `foundation`, `dspm` | Yes |
| `02-Ensure-PurviewAccount.ps1` | Ensure Purview (governance) account | Required for DSPM scans & insights | `foundation`, `dspm` | Yes |
| `03-Register-DataSource.ps1` | Register data sources in Purview | DSPM **Discovery** | `scans`, `dspm` | Yes |
| `04-Run-Scan.ps1` | Create & trigger scans | DSPM **Classification/Scan** | `scans`, `dspm` | Yes |
| `05-Assign-AzurePolicies.ps1` | Assign built‑in Azure Policies | Prevent misconfigurations that leak AI data | `policies`, `dspm`, `defender` | Yes |
| `06-Enable-DefenderPlans.ps1` | Enable Defender for Cloud plans | Telemetry & protections for AI resources | `defender` | Yes |
| `07-Enable-Diagnostics.ps1` | Route diagnostics to Log Analytics | Monitoring trail supporting DSPM analytics | `defender`, `diagnostics`, `foundry` | Yes |
| `08-Ensure-PrivateEndpoints.ps1` | Create Private Endpoints | Data egress control for AI data paths | `networking`, `dspm`, `foundry` | Yes |
| `09-Ensure-KeyVaultSecrets.ps1` | Ensure secrets in Key Vault | Secures keys used by Content Safety | `ops`, `foundry` | Yes |
| `10-Connect-Compliance.ps1` | Open IPPS (Compliance PowerShell) | Required session for governance cmdlets | `compliance`, `dspm` | No |
| `11-Enable-UnifiedAudit.ps1` | Enable Unified Audit ingestion | Backbone for Activity Explorer & DSPM | `audit`, `dspm`, `compliance` | No |
| `12-Create-DlpPolicy.ps1` | Create DLP policy & rules | Prevent high‑risk exfiltration | `policies`, `dspm` | Yes |
| `13-Create-SensitivityLabel.ps1` | Create labels & publish | Classification/Protection pillar | `policies`, `dspm` | Yes |
| `14-Create-RetentionPolicy.ps1` | Create retention policies & rules | Lifecycle management for AI data | `policies`, `dspm` | Yes |
| `15-Create-SensitiveInfoType-Stub.ps1` | Stub for custom SITs | Extend detection (future/portal) | `policies`, `dspm` | No |
| `16-Create-TrainableClassifier-Stub.ps1` | Stub for classifiers | Trainable ML detection (portal) | `policies`, `dspm` | No |
| `17-Export-ComplianceInventory.ps1` | Export labels/DLP/retention inventory | Evidence & documentation | `ops`, `dspm` | No |
| `18-Set-CompliancePermissions.ps1` | Add user to Compliance role group | Grants governance authoring rights | `ops`, `compliance`, `dspm` | No |
| `19-Ensure-ActivityContentTypes.ps1` | (Re)subscribe audit content types | Ensures correct audit feeds | `audit`, `dspm` | Yes |
| `20-Subscribe-ManagementActivity.ps1` | Start Management Activity API subscriptions | Feeds audit stream | `audit`, `dspm` | Yes |
| `21-Export-Audit.ps1` | Export audit (JSON/CSV) | Data for DSPM analytics | `audit`, `dspm` | Yes |
| `22-Ship-AuditToStorage.ps1` | Upload audit files to ADLS Gen2 | Long‑term evidence / Fabric ingestion | `audit`, `ops` | No |
| `23-Ship-AuditToFabricLakehouse-Stub.ps1` | Stub to land audit in Fabric | Build dashboards for AI governance | `audit`, `foundry` | No |
| `24-Create-BudgetAlert-Stub.ps1` | Stub for budget/alerts | Guardrails for PAYG usage | `ops` | No |
| `25-Tag-ResourcesFromSpec.ps1` | Apply tags from spec | Posture metadata for AI assets | `ops`, `foundry`, `dspm` | Yes |
| `26-Register-OneLake.ps1` | Register OneLake root as data source | DSPM Discovery for Fabric | `scans`, `dspm`, `foundry` | Yes |
| `27-Register-FabricWorkspace.ps1` | Register a specific Fabric workspace | Targeted DSPM scanning | `scans`, `dspm`, `foundry` | Yes |
| `28-Trigger-OneLakeScan.ps1` | Trigger scan for OneLake | DSPM Classification/Scan | `scans`, `dspm`, `foundry` | Yes |
| `29-Trigger-FabricWorkspaceScan.ps1` | Trigger scan for workspace | DSPM Classification/Scan | `scans`, `dspm`, `foundry` | Yes |
| `30-Foundry-RegisterResources.ps1` | Validate & tag Foundry resources | Governance metadata for AI | `foundry`, `ops` | Yes |
| `31-Foundry-ConfigureContentSafety.ps1` | Configure Content Safety blocklists | Prompt filtering guardrails | `foundry`, `defender` | Yes |
| `32-Foundry-GenerateBindings-Stub.ps1` | Stub for AOAI/AI Search bindings | App‑side wiring to governed services | `foundry` | No |
| `33-Compliance-Report.ps1` | Quick compliance summary | “Are we protected?” snapshot | `ops`, `dspm` | No |
| `34-Validate-Posture.ps1` | Validations (audit enabled, plans) | Sanity checks of posture | `ops`, `dspm`, `defender` | Yes |

## How to Run 
```powershell
# 1) Create a spec template
./00-New-DspmSpec.ps1 -OutFile ./spec.dspm.json

# 2) Provision Azure side
./01-Ensure-ResourceGroup.ps1 -SpecPath ./spec.dspm.json
./02-Ensure-PurviewAccount.ps1  -SpecPath ./spec.dspm.json

# 3) Compliance backbone
./10-Connect-Compliance.ps1
./11-Enable-UnifiedAudit.ps1

# 4) Governance policies
./12-Create-DlpPolicy.ps1 -SpecPath ./spec.dspm.json
./13-Create-SensitivityLabel.ps1 -SpecPath ./spec.dspm.json
./14-Create-RetentionPolicy.ps1 -SpecPath ./spec.dspm.json

# 5) DSPM scans
./03-Register-DataSource.ps1 -SpecPath ./spec.dspm.json
./04-Run-Scan.ps1 -SpecPath ./spec.dspm.json

# 6) Audit & monitoring
./20-Subscribe-ManagementActivity.ps1 -SpecPath ./spec.dspm.json
./21-Export-Audit.ps1 -SpecPath ./spec.dspm.json

# 7) AI security posture
./05-Assign-AzurePolicies.ps1 -SpecPath ./spec.dspm.json
./06-Enable-DefenderPlans.ps1 -SpecPath ./spec.dspm.json
./07-Enable-Diagnostics.ps1 -SpecPath ./spec.dspm.json

# 8) AI Foundry governance
./30-Foundry-RegisterResources.ps1 -SpecPath ./spec.dspm.json
./31-Foundry-ConfigureContentSafety.ps1 -SpecPath ./spec.dspm.json
```

### 1. Install Prerequisites

```bash
# Install PowerShell 7 (if not already installed)
# For Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y powershell

# Install Azure CLI (if not already installed)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### 2. Authenticate

```bash
# Azure CLI authentication
az login

# Set your subscription
az account set --subscription "Your-Subscription-Name"
```

### 3. Run Scripts in Order

```bash
# Step 1: Enable Defender for Cloud
pwsh ./enable_defender_for_cloud.ps1

# Step 2: Enable Defender for AI services
pwsh ./enable_defender_for_ai.ps1

# Step 3: Enable user prompt evidence
pwsh ./enable_user_prompt_evidence.ps1

# Step 4: Connect to Purview DSPM (optional but recommended)
pwsh ./connect_defender_to_purview.ps1

# Step 5: Verify configuration
pwsh ./verify_defender_ai_configuration.ps1
```

## 🔐 Security Features

### Threat Protection
- **Prompt Injection Detection**: Identifies malicious prompts attempting to bypass AI guardrails
- **Data Exfiltration Prevention**: Detects attempts to extract sensitive data through AI
- **Jailbreak Attempts**: Monitors for attempts to circumvent AI safety measures
- **Anomalous Usage Patterns**: Identifies unusual AI usage that may indicate compromise

### Evidence Collection
- **User Prompt Capture**: Records AI prompts for security analysis
- **Model Response Tracking**: Captures AI responses for threat investigation
- **Metadata Collection**: Gathers contextual information (user, timestamp, IP)
- **Sensitive Data Detection**: Identifies sensitive information in prompts/responses

### Compliance & Governance
- **Purview Integration**: Sends data to Purview DSPM for compliance tracking
- **SIT Classification**: Automatically classifies sensitive information types
- **Audit Logging**: Complete audit trail for all AI interactions
- **Retention Policies**: Configurable data retention for compliance

## 📊 Monitoring & Alerts

After configuration, monitor your AI security:

1. **Defender for Cloud Portal**: [Azure Portal - Defender for Cloud](https://portal.azure.com/#view/Microsoft_Azure_Security/SecurityMenuBlade/~/0)
2. **AI Security Alerts**: Navigate to Security Alerts and filter by "AI"
3. **Data and AI Dashboard**: Review the Data and AI security dashboard (Preview)
4. **Purview Integration**: View AI data in [Purview DSPM](https://purview.microsoft.com/purviewforai/overview)

### Key Metrics to Monitor
- Number of AI threat alerts
- Prompt injection attempts
- Data exfiltration detections
- Jailbreak attempts
- User prompt evidence collected
- Purview integration status

## 🏗️ Architecture Integration

```
┌──────────────────────────────────────────────────────────────┐
│                    Azure AI Services                         │
│  ┌────────────────┐    ┌────────────────┐    ┌────────────┐ │
│  │ Azure OpenAI   │    │  AI Search     │    │ AI Foundry │ │
│  │ (Prompts/      │    │  (Documents)   │    │ (Projects) │ │
│  │  Responses)    │    │                │    │            │ │
│  └────────────────┘    └────────────────┘    └────────────┘ │
└──────────────────────────────────────────────────────────────┘
                              │
                    Security Monitoring
                              ▼
┌──────────────────────────────────────────────────────────────┐
│              Microsoft Defender for Cloud                    │
├──────────────────────────────────────────────────────────────┤
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │  AI Services   │  │ User Prompt    │  │ Threat         │ │
│  │  Plan          │  │ Evidence       │  │ Detection      │ │
│  └────────────────┘  └────────────────┘  └────────────────┘ │
└──────────────────────────────────────────────────────────────┘
                              │
                    Governance Integration
                              ▼
┌──────────────────────────────────────────────────────────────┐
│           Microsoft Purview DSPM for AI                      │
│  • Sensitive Information Classification                      │
│  • Compliance Reporting                                      │
│  • Audit Logging                                             │
│  • Risk Analytics                                            │
└──────────────────────────────────────────────────────────────┘
```

## 🔧 Troubleshooting

### Common Issues

**Defender for Cloud Not Enabling**
- Verify you have appropriate permissions (Security Admin or Contributor)
- Check subscription is not disabled or in grace period
- Ensure no Azure Policy blocking Defender enablement

**AI Services Plan Not Available**
- Confirm you have AI services deployed in subscription
- Verify subscription supports Defender for AI (check region availability)
- Wait 10-15 minutes after Defender for Cloud enablement

**User Prompt Evidence Not Collecting**
- Ensure Azure OpenAI uses Microsoft Entra ID authentication
- Verify user context is included in API calls
- Check content filtering is not opted out
- Allow 24-48 hours for data collection to begin

**Purview Integration Issues**
- Confirm Microsoft Purview DSPM is enabled (requires M365 E5)
- Verify Purview account is in same tenant
- Check network connectivity between services

## 💰 Cost Considerations

### Defender for Cloud Pricing
- **Free tier**: Basic security hygiene and recommendations
- **Defender CSPM**: ~$5/resource/month for enhanced security posture
- **Defender for AI Services**: Based on API transactions volume

### What's Included
- ✅ Threat detection for AI workloads
- ✅ Security alerts and recommendations
- ✅ User prompt evidence collection (limited retention)
- ✅ Integration with Microsoft Sentinel

### Additional Costs
- **Extended data retention**: Beyond default retention period
- **Log Analytics**: If routing logs to Log Analytics workspace
- **Purview DSPM**: Requires Microsoft 365 E5 license (separate)

**Cost estimation**: [Defender for Cloud Pricing](https://azure.microsoft.com/pricing/details/defender-for-cloud/)

## 📖 References

### Microsoft Documentation
- [Enable threat protection for AI services](https://learn.microsoft.com/azure/defender-for-cloud/ai-onboarding)
- [AI threat protection overview](https://learn.microsoft.com/azure/defender-for-cloud/ai-threat-protection)
- [Data and AI security dashboard](https://learn.microsoft.com/azure/defender-for-cloud/data-aware-security-dashboard-overview)
- [Gain end-user context for Azure AI](https://learn.microsoft.com/azure/defender-for-cloud/gain-end-user-context-ai)
- [Prepare for AI security](https://learn.microsoft.com/security/security-for-ai/prepare)

### Integration Documentation
- [Connect Defender to Purview](https://learn.microsoft.com/azure/defender-for-cloud/ai-onboarding#enable-data-security-for-azure-ai-with-microsoft-purview)
- [Purview DSPM for AI](https://learn.microsoft.com/purview/ai-microsoft-purview)
- [Security for AI guide](https://learn.microsoft.com/security/security-for-ai/)

## 🤝 Integration with Existing Scripts

These Defender scripts complement the existing automation:

- **Fabric_Purview_Automation**: Creates data infrastructure and governance
- **PurviewGovernance**: Enables DSPM for AI and compliance policies
- **DefenderScripts** (NEW): Adds threat protection and security monitoring
- **OneLakeIndex**: Enables AI Search integration

Together, they provide **comprehensive AI security** from infrastructure to threat detection with integrated governance and compliance.


