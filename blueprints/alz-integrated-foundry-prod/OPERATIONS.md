# ALZ Integrated Foundry Prod Operations

Use this runbook for customer-side plan review and apply operations for the `alz-integrated-foundry-prod` blueprint.

## Working Directory

Run Terraform from this directory only:

```powershell
C:\Users\admin-si\terraform-ailz\ai-landing-zone-accelerator-tf-team\blueprints\alz-integrated-foundry-prod
```

Confirm the expected state is present before planning:

```powershell
terraform state list | Measure-Object -Line
```

The current deployed environment had 112 resources in state during review.

## Required Identity Inputs

Set these values before planning or applying:

```powershell
$env:ARM_SUBSCRIPTION_ID = "d0caa005-e9fb-478a-8a7d-ea0cc2654f52"
$env:ARM_TENANT_ID = "3cfc49f9-956e-4e4e-a1b6-e03368c2e448"
$env:TF_VAR_foundry_admin_entra_group_object_id = "<admin-group-object-id>"
$env:TF_VAR_foundry_ai_developer_entra_group_object_id = "<developer-group-object-id>"
```

Developer project access is opt-in. To grant the developer group Foundry User on a project, set the project map key explicitly:

```powershell
$env:TF_VAR_foundry_developer_project_keys = '["aif_prj_default"]'
```

Leave `TF_VAR_foundry_developer_project_keys` unset or set to `[]` when no project should grant developer access by default.

## Plan Workflow

Always generate a saved plan and full text output before applying:

```powershell
git pull
terraform init
terraform plan -out tfplan
terraform show -no-color tfplan | Out-File -Encoding utf8 plan.txt
```

If the account-level capability host was created manually during incident remediation, import it before planning so Terraform owns it:

```powershell
$acct = "/subscriptions/d0caa005-e9fb-478a-8a7d-ea0cc2654f52/resourceGroups/ai-lz-rg-default-n1r2z/providers/Microsoft.CognitiveServices/accounts/ai-foundry-s50j"
terraform import 'module.test.module.foundry_ptn.azapi_resource.ai_agent_capability_host[0]' "$acct/capabilityHosts/ai-agent-service"
```

If manual admin role assignments were created before Terraform managed them, either remove the duplicate assignments or import them before planning:

```powershell
terraform import 'azurerm_role_assignment.foundry_account_admin[0]' '<account-foundry-owner-assignment-id>'
terraform import 'azurerm_role_assignment.foundry_account_admin_contributor[0]' '<rg-cognitive-services-contributor-assignment-id>'
```

Review `plan.txt` manually before apply. Do not rely only on filtered terminal output.

Expected project replacement actions may include creates for:

- `module.test.module.foundry_ptn.module.ai_foundry_project["aif_prj_default"]`
- `azurerm_role_assignment.foundry_account_admin[0]`
- `azurerm_role_assignment.foundry_account_admin_contributor[0]`
- `azurerm_role_assignment.foundry_project_admin["aif_prj_default"]`

Expected cleanup may include destroys for old `project_1` child resources only, such as project-scoped role assignments and wait helpers.

Do not apply if `plan.txt` shows destroy or replacement for shared infrastructure:

- Foundry account `ai-foundry-s50j`
- Account capability host `ai-agent-service`
- VNet, subnets, route tables, NSGs, or private endpoints
- Key Vault, Storage account, Cosmos DB account, or AI Search service
- DDoS Protection Plan association on the VNet

After review, apply the saved plan:

```powershell
terraform apply tfplan
```

If apply fails because Azure RBAC propagation is not complete, wait several minutes and run a new plan/apply cycle.

## Creating Additional Foundry Projects

In the new Foundry portal, the top-left **Create new project** flow creates a project with a new or selected **Microsoft Foundry resource**. For projects that must live under the Terraform-managed Foundry account, use one of these paths instead:

- Preferred: add another entry to `ai_foundry_definition.ai_projects` in `main.tf`, then run the normal saved plan/apply workflow. This keeps project RBAC, connections, and capability hosts under Terraform management.
- Portal: select **Operate** in the upper-right navigation, select **Admin**, select the parent Foundry resource `ai-foundry-s50j`, then select **Add project**.
- CLI: create a child project under the existing account:

```powershell
az cognitiveservices account project create `
	--name ai-foundry-s50j `
	--resource-group ai-lz-rg-default-n1r2z `
	--project-name <project-name> `
	--location swedencentral
```

Avoid creating a new **Microsoft Foundry resource** for project-only additions unless the intent is a separate parent account with separate networking, deployments, and shared connections.

## Admin RBAC Ownership

Terraform owns these admin group assignments:

- Foundry Owner at the Foundry account scope
- Cognitive Services Contributor at the resource group scope
- Foundry Owner on each Terraform-managed Foundry project

Manual role assignments with the same principal, role, and scope can cause `RoleAssignmentExists` during apply. Import or remove duplicates before applying.

## Foundry Agent Service Networking Note

The account-level Agent Service capability host must exist before project capability hosts can be created. In the VNet-injection deployment path, verify the account host exists before troubleshooting project capability host failures:

```powershell
$acct = "/subscriptions/d0caa005-e9fb-478a-8a7d-ea0cc2654f52/resourceGroups/ai-lz-rg-default-n1r2z/providers/Microsoft.CognitiveServices/accounts/ai-foundry-s50j"
az rest --method get --url "https://management.azure.com$acct/capabilityHosts/ai-agent-service?api-version=2025-10-01-preview"
```

The response should show `properties.provisioningState` as `Succeeded`.
