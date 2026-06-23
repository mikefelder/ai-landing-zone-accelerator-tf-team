module "foundry_ptn" {
  source  = "Azure/avm-ptn-aiml-ai-foundry/azurerm"
  version = "0.10.0"

  #configure the base resource
  base_name                  = coalesce(var.name_prefix, "foundry")
  location                   = azurerm_resource_group.this.location
  resource_group_resource_id = azurerm_resource_group.this.id
  #pass through the resource definitions
  ai_foundry                          = local.foundry_ai_foundry
  ai_model_deployments                = local.foundry_openai_model_deployments
  ai_projects                         = local.foundry_ai_projects
  ai_search_definition                = local.foundry_ai_search_definition
  cosmosdb_definition                 = local.foundry_cosmosdb_definition
  create_byor                         = var.ai_foundry_definition.create_byor
  create_private_endpoints            = var.ai_foundry_definition.create_private_endpoints
  diagnostic_settings                 = local.foundry_diagnostic_settings
  enable_telemetry                    = var.enable_telemetry
  key_vault_definition                = local.foundry_key_vault_definition
  private_endpoint_subnet_resource_id = var.ai_foundry_definition.create_private_endpoints ? local.subnet_ids["PrivateEndpointSubnet"] : null
  storage_account_definition          = local.foundry_storage_account_definition

  depends_on = [azapi_resource_action.purge_ai_foundry]
}

# Anthropic Claude (and other Azure Marketplace partner) model deployments.
# The foundry pattern module cannot create these because its deployment body
# omits the required `modelProviderData` attestation and leaves azapi schema
# validation enabled. We create them directly against the Foundry account the
# module provisions. Sending `modelProviderData` auto-accepts the Anthropic
# Marketplace offer terms, so review https://www.anthropic.com/legal/commercial-terms
# before applying. Foundry serializes deployment creation per account, so this
# resource is created after the module to avoid 409 conflicts.
resource "azapi_resource" "ai_anthropic_model_deployment" {
  for_each = local.foundry_anthropic_model_deployments

  type                      = "Microsoft.CognitiveServices/accounts/deployments@2025-10-01-preview"
  name                      = each.value.name
  parent_id                 = module.foundry_ptn.ai_foundry_id
  schema_validation_enabled = false # required to allow modelProviderData

  body = {
    sku = {
      name     = each.value.scale.type
      capacity = each.value.scale.capacity
    }
    properties = {
      model = {
        format  = each.value.model.format
        name    = each.value.model.name
        version = each.value.model.version
      }
      modelProviderData = {
        organizationName = each.value.model_provider_data.organization_name
        countryCode      = each.value.model_provider_data.country_code
        industry         = each.value.model_provider_data.industry
      }
      raiPolicyName        = each.value.rai_policy_name
      versionUpgradeOption = each.value.version_upgrade_option
    }
  }

  depends_on = [module.foundry_ptn]
}

resource "azapi_resource_action" "purge_ai_foundry" {
  count = var.ai_foundry_definition.purge_on_destroy ? 1 : 0

  method      = "DELETE"
  resource_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.CognitiveServices/locations/${azurerm_resource_group.this.location}/resourceGroups/${azurerm_resource_group.this.name}/deletedAccounts/${local.ai_foundry_name}"
  type        = "Microsoft.Resources/resourceGroups/deletedAccounts@2021-04-30"
  when        = "destroy"

  depends_on = [time_sleep.purge_ai_foundry_cooldown]
}

resource "time_sleep" "purge_ai_foundry_cooldown" {
  count = var.ai_foundry_definition.purge_on_destroy ? 1 : 0

  destroy_duration = "900s" # 10m

  depends_on = [module.ai_lz_vnet, module.byo_subnets]
}
