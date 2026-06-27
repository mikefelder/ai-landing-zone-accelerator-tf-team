# Customer Call Walkthrough - ALZ Integrated Foundry Prod Recovery

Use this as the live-call checklist for the next customer session. The goal is to pull the latest repo changes, bring manually-created resources into Terraform state, generate a fresh saved plan, review it carefully, and only then apply.

Do not apply an old `tfplan`. Always regenerate the plan after pulling the latest commit.

## 1. Confirm Starting Context

Confirm with the customer before running commands:

- They are in the prod blueprint working directory.
- They are targeting subscription `d0caa005-e9fb-478a-8a7d-ea0cc2654f52`.
- The existing Foundry account is `ai-foundry-s50j` in resource group `ai-lz-rg-default-n1r2z`.
- The manually-created account capability host is expected to be named `ai-agent-service`.
- The desired project is the net-new project `aif-prj-default`.
- Developer access should be project opt-in only, not account-wide by default.

Open PowerShell in:

```powershell
cd C:\Users\admin-si\terraform-ailz\ai-landing-zone-accelerator-tf-team\blueprints\alz-integrated-foundry-prod
```

## 2. Set Session Variables

Set the Azure/Terraform inputs for this terminal session.

```powershell
$sub = "d0caa005-e9fb-478a-8a7d-ea0cc2654f52"
$tenant = "3cfc49f9-956e-4e4e-a1b6-e03368c2e448"
$rg = "ai-lz-rg-default-n1r2z"
$foundryAccount = "ai-foundry-s50j"

# Replace these with the real Entra group object IDs.
$adminGroupObjectId = "<foundry-admin-group-object-id>"
$developerGroupObjectId = "<foundry-users-group-object-id>"

$env:ARM_SUBSCRIPTION_ID = $sub
$env:ARM_TENANT_ID = $tenant
$env:TF_VAR_foundry_admin_entra_group_object_id = $adminGroupObjectId
$env:TF_VAR_foundry_ai_developer_entra_group_object_id = $developerGroupObjectId

# Leave this unset or [] if developers should not yet receive access to a project.
# Set it to ["aif_prj_default"] only when ready to grant Foundry User on the default project.
$env:TF_VAR_foundry_developer_project_keys = '[]'

$rgScope = "/subscriptions/$sub/resourceGroups/$rg"
$accountScope = "$rgScope/providers/Microsoft.CognitiveServices/accounts/$foundryAccount"
$acct = $accountScope

az account set --subscription $sub
az account show --query "{subscription:id, tenant:tenantId, name:name}" -o table
```

If `az account show` does not show the expected subscription and tenant, stop and fix the Azure login/context before continuing.

## 3. Pull Latest Code And Initialize

Pull the latest repo state. The expected latest commit includes the patched local Foundry module and the prod hardening/RBAC changes.

```powershell
git pull
git log --oneline -3
terraform init
```

Expected recent commits include:

```text
5f1ac54 Track patched Foundry module files instead of gitlink
63c3c17 Patch Foundry module to manage VNet-injected account capability host
652fc38 Harden prod Foundry blueprint operations and access controls
```

## 4. Quick State And Resource Checks

Confirm Terraform sees the existing state and Azure sees the account-level capability host.

```powershell
terraform state list | Measure-Object -Line

az rest `
  --method get `
  --url "https://management.azure.com$acct/capabilityHosts/ai-agent-service?api-version=2025-10-01-preview" `
  --query "{name:name, provisioningState:properties.provisioningState, customerSubnet:properties.customerSubnet}" `
  -o jsonc
```

Expected:

- Terraform state count is roughly the existing deployed environment count. It was 112 during prior review.
- The capability host exists and has `provisioningState` of `Succeeded`.

If the capability host GET returns not found, stop. The new patched Terraform can create it, but the plan must be reviewed especially carefully because this was the incident-critical missing resource.

## 5. Import The Manually-Created Capability Host

If the capability host exists but is not already in Terraform state, import it.

```powershell
terraform state show 'module.test.module.foundry_ptn.azapi_resource.ai_agent_capability_host[0]'
```

If that command says the resource is not found in state, run:

```powershell
terraform import 'module.test.module.foundry_ptn.azapi_resource.ai_agent_capability_host[0]' "$acct/capabilityHosts/ai-agent-service"
```

Then verify:

```powershell
terraform state show 'module.test.module.foundry_ptn.azapi_resource.ai_agent_capability_host[0]'
```

## 6. Import Intended Manual Admin RBAC

The preferred path is to import correct manual RBAC assignments rather than delete and recreate them.

Terraform now owns these admin assignments:

- Foundry Owner at the Foundry account scope.
- Cognitive Services Contributor at the resource group scope.
- Foundry Owner on each Terraform-managed project.

List the current manual assignments and capture their `id` values.

```powershell
az role assignment list `
  --assignee $adminGroupObjectId `
  --scope $accountScope `
  --query "[?roleDefinitionName=='Foundry Owner'].{id:id, role:roleDefinitionName, scope:scope, principal:principalName}" `
  -o table

az role assignment list `
  --assignee $adminGroupObjectId `
  --scope $rgScope `
  --query "[?roleDefinitionName=='Cognitive Services Contributor'].{id:id, role:roleDefinitionName, scope:scope, principal:principalName}" `
  -o table
```

Import the two existing assignment IDs if they exist and match the intended group, role, and scope.

```powershell
terraform import 'azurerm_role_assignment.foundry_account_admin[0]' '<account-foundry-owner-assignment-id>'

terraform import 'azurerm_role_assignment.foundry_account_admin_contributor[0]' '<rg-cognitive-services-contributor-assignment-id>'
```

If either assignment does not exist, do not create it manually. Let Terraform plan/create it.

## 7. Clean Up Broad Developer Access If Present

Developer access should be project-scoped and opt-in. Check for broad account-scoped developer grants that should not remain.

```powershell
az role assignment list `
  --assignee $developerGroupObjectId `
  --scope $accountScope `
  --query "[?roleDefinitionName=='Foundry User' || roleDefinitionName=='Azure AI User' || roleDefinitionName=='Cognitive Services User'].{id:id, role:roleDefinitionName, scope:scope, principal:principalName}" `
  -o table
```

If the output shows broad account-scoped developer access, confirm with the customer and remove only the role that exists.

```powershell
az role assignment delete `
  --assignee $developerGroupObjectId `
  --role "Foundry User" `
  --scope $accountScope

az role assignment delete `
  --assignee $developerGroupObjectId `
  --role "Azure AI User" `
  --scope $accountScope

az role assignment delete `
  --assignee $developerGroupObjectId `
  --role "Cognitive Services User" `
  --scope $accountScope
```

It is okay if one or more delete commands report no matching assignment, provided the list command confirms no broad developer assignment remains.

## 8. Generate A Fresh Saved Plan

Remove stale local plan artifacts and generate a new plan.

```powershell
Remove-Item -Force .\tfplan, .\plan.txt -ErrorAction SilentlyContinue

terraform plan -out tfplan
terraform show -no-color tfplan | Out-File -Encoding utf8 plan.txt
```

Do not apply yet.

## 9. Review Plan Before Apply

Open `plan.txt` and review the full file, not only filtered output.

Expected creates/changes:

- Creation of the new project `aif-prj-default`.
- Creation of project-scoped resources for `aif_prj_default`.
- Creation of intended Terraform-managed RBAC that was not imported because it did not already exist.
- Cleanup of old `project_1` child resources only, if Terraform still tracks old project resources.

Do not apply if the plan shows destroy or replacement for:

- Foundry account `ai-foundry-s50j`.
- Account capability host `ai-agent-service`.
- VNet `ai-lz-vnet-default-1`.
- Any existing subnet, route table, NSG, private endpoint, or private DNS zone link that should remain.
- DDoS Protection Plan association on the VNet.
- Key Vault, Storage account, Cosmos DB account, or AI Search service.

Useful targeted checks:

```powershell
Select-String -Path .\plan.txt -Pattern "must be replaced|will be destroyed|-/\+|DDoS|ai-foundry-s50j|ai-agent-service|ai-lz-vnet-default-1|project_1|aif-prj-default" -Context 2,3
```

Treat the filtered output as a navigation aid only. The final decision should come from reviewing the full `plan.txt`.

## 10. Apply The Reviewed Saved Plan

Apply only after everyone agrees the saved plan is safe.

```powershell
terraform apply tfplan
```

If apply fails with `RoleAssignmentExists`, find the duplicate assignment ID, import it into the matching Terraform resource, then generate a new plan.

If apply fails with RBAC propagation or authorization errors, wait several minutes, verify the caller still has required rights, then regenerate the plan before retrying.

Do not rerun `terraform apply tfplan` after changing state or variables. Generate a new saved plan first.

## 11. Post-Apply Checks

Verify the key resources after apply.

```powershell
terraform state list | Select-String "aif_prj_default|ai_agent_capability_host|foundry_"

az rest `
  --method get `
  --url "https://management.azure.com$acct/capabilityHosts/ai-agent-service?api-version=2025-10-01-preview" `
  --query "{name:name, provisioningState:properties.provisioningState, customerSubnet:properties.customerSubnet}" `
  -o jsonc

az role assignment list `
  --assignee $adminGroupObjectId `
  --scope $accountScope `
  --query "[?roleDefinitionName=='Foundry Owner'].{role:roleDefinitionName, scope:scope, principal:principalName}" `
  -o table

az role assignment list `
  --assignee $adminGroupObjectId `
  --scope $rgScope `
  --query "[?roleDefinitionName=='Cognitive Services Contributor'].{role:roleDefinitionName, scope:scope, principal:principalName}" `
  -o table
```

Confirm in the Azure AI Foundry portal:

- Account `ai-foundry-s50j` opens normally.
- Project `aif-prj-default` exists.
- Agent Service/project capability host errors are gone.
- Admin group can manage the account/project.
- Developer group does not have account-wide default access unless deliberately granted elsewhere.

## 12. If The Plan Looks Unsafe

Stop and keep the artifacts:

```powershell
Copy-Item .\plan.txt .\plan-review-blocked.txt -Force
terraform show -json tfplan | Out-File -Encoding utf8 plan.json
```

Capture:

- The exact Terraform command output.
- The relevant `plan.txt` sections around any destroy/replace.
- Whether the capability host and RBAC imports completed.
- Current `git log --oneline -3` output.

Do not apply while a shared infrastructure destroy or replacement is unexplained.
