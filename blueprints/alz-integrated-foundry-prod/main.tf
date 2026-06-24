terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.21"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  # Target the pre-vended landing zone subscription. Leave var.subscription_id
  # null to fall back to ARM_SUBSCRIPTION_ID / the Azure CLI's active subscription.
  subscription_id     = var.subscription_id
  tenant_id           = var.tenant_id
  storage_use_azuread = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_client_config" "current" {}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
# DISABLED: random region selection (using fixed swedencentral now)
# module "regions" {
#   source  = "Azure/avm-utl-regions/azurerm"
#   version = "0.9.2"
# }
#
# # This allows us to randomize the region for the resource group.
# resource "random_integer" "region_index" {
#   max = length(module.regions.regions) - 1
#   min = 0
# }
# ## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# DISABLED: ipify data source (only used by disabled example_hub)
# data "http" "ip" {
#   url = "https://api.ipify.org/"
#   retry {
#     attempts     = 5
#     max_delay_ms = 1000
#     min_delay_ms = 500
#   }
# }

#create a sample hub to mimic an existing network landing zone configuration
# DISABLED: example_hub is commented out in favor of real ALZ hub integration.
# TODO: wire to real ALZ hub VNet post-deployment. See README "Target subscription" section.
# module "example_hub" {
#   source = "../../modules/example_hub_vnet"
#
#   location            = "swedencentral"
#   resource_group_name = "default-example-${module.naming.resource_group.name_unique}"
#   #resource_group_name = "default-example-rg-ivrh-1"
#   vnet_definition = {
#     address_space = "10.10.0.0/24"
#   }
#   deployer_ip_address = "${data.http.ip.response_body}/32"
#   enable_telemetry    = var.enable_telemetry
#   name_prefix         = "${module.naming.resource_group.name_unique}-hub"
# }

module "test" {
  source = "../../"

  location            = "swedencentral"
  resource_group_name = "ai-lz-rg-default-${substr(module.naming.unique-seed, 0, 5)}"
  #resource_group_name = "ai-lz-rg-default-ivrhi-1"
  vnet_definition = {
    name          = "ai-lz-vnet-default-1"
    address_space = ["172.20.124.0/23"] # infra-allocated /23. 172.16.0.0/12 is a supported RFC1918 range for Foundry agent capabilityHost injection (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 are all valid).
    # TODO: set dns_servers to ALZ hub DNS resolver IPs or custom DNS; currently commented out.
    # dns_servers   = ["<hub-dns-resolver-ip-1>", "<hub-dns-resolver-ip-2>"]
    # Explicit subnet prefixes for the /23. The delegated Microsoft.App/environments subnets
    # (AIFoundrySubnet agent injection + ContainerAppEnvironmentSubnet) and the PrivateEndpointSubnet
    # are sized at /26 to give agent/Container Apps/private-endpoint scaling headroom well above
    # Azure's /27 delegation minimum. The module's default cidrsubnet math would also yield valid
    # /27s on a /23, but pinning keeps the layout explicit and predictable.
    # 172.20.125.32 - 172.20.125.255 left free for growth.
    subnets = {
      PrivateEndpointSubnet         = { address_prefix = "172.20.124.0/26" }
      AIFoundrySubnet               = { address_prefix = "172.20.124.64/26" }
      ContainerAppEnvironmentSubnet = { address_prefix = "172.20.124.128/26" }
      DevOpsBuildSubnet             = { address_prefix = "172.20.124.192/27" }
      AppGatewaySubnet              = { address_prefix = "172.20.124.224/27" }
      APIMSubnet                    = { address_prefix = "172.20.125.0/27" }
    }
    # TODO: vnet_peering_configuration — replace with real ALZ hub VNet resource ID
    # vnet_peering_configuration = {
    #   peer_vnet_resource_id = "/subscriptions/.../providers/Microsoft.Network/virtualNetworks/<hub-vnet-name>"
    # }
  }
  ai_foundry_definition = {
    purge_on_destroy = false
    ai_foundry = {
      create_ai_agent_service    = true
      enable_diagnostic_settings = false
    }
    # No model deployments are provisioned by this blueprint. Add OpenAI (first-party)
    # deployments here when ready; partner/Marketplace models (e.g. Anthropic) are
    # intentionally omitted to avoid Marketplace licensing/attestation requirements.
    ai_model_deployments = {}
    ai_projects = {
      project_1 = {
        name                       = "project-1"
        description                = "Project 1 description"
        display_name               = "Project 1 Display Name"
        create_project_connections = true
        ai_search_connection = {
          new_resource_map_key = "this"
        }
        cosmos_db_connection = {
          new_resource_map_key = "this"
        }
        storage_account_connection = {
          new_resource_map_key = "this"
        }
      }
    }
    ai_search_definition = {
      this = {
      }
    }
    cosmosdb_definition = {
      this = {
        # Azure no longer supports enabling analytical storage at account-create time
        # ("Enabling Analytical storage account creation is no longer supported").
        # The agent-service Cosmos store does not need it, so disable it explicitly
        # (the module schema still defaults this to true).
        analytical_storage_enabled = false
      }
    }
    key_vault_definition = {
      this = {
      }
    }

    storage_account_definition = {
      this = {
        shared_access_key_enabled = true #configured for testing
        endpoints = {
          blob = {
            type = "blob"
          }
        }
      }
    }
  }
  apim_definition = {
    deploy             = false
    deploy_sample_apis = true
    publisher_email    = "DoNotReply@exampleEmail.com"
    publisher_name     = "Azure API Management"
  }
  app_gateway_definition = {
    deploy = false
  }
  bastion_definition = {
    deploy = false
  }
  container_app_environment_definition = {
    deploy                     = false
    enable_diagnostic_settings = false
  }
  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = true
  genai_app_configuration_definition = {
    deploy                     = false
    enable_diagnostic_settings = false
  }
  genai_container_registry_definition = {
    deploy                     = false
    enable_diagnostic_settings = false
  }
  genai_cosmosdb_definition = {
    deploy            = false
    consistency_level = "Session"
  }
  genai_key_vault_definition = {}
  genai_storage_account_definition = {
    deploy = false
  }
  ks_ai_search_definition = {
    deploy                     = false
    enable_diagnostic_settings = false
  }
  ks_bing_grounding_definition = {
    deploy = false
  }
  private_dns_zones = {
    azure_policy_pe_zone_linking_enabled = true
    # TODO: existing_zones_resource_group_resource_id — set to ALZ hub's private DNS zone RG resource ID
    # existing_zones_resource_group_resource_id = "/subscriptions/.../resourceGroups/<hub-dns-rg>"
  }
}

# ---------------------------------------------------------------------------
# Foundry RBAC for Entra security groups (per-project scope)
# ---------------------------------------------------------------------------
# Built-in Foundry role definition GUIDs. GUIDs are used instead of display
# names because the Foundry RBAC roles were recently renamed (e.g. "Azure AI
# Owner" -> "Foundry Owner") and the role IDs are stable across the rename.
locals {
  foundry_owner_role_definition_id = "c883944f-8b7b-4483-af10-35834be79c4a" # Foundry Owner (full manage + build/develop)
  foundry_user_role_definition_id  = "53ca6127-db72-4b80-b1b0-d745d6d5456d" # Foundry User  (least-privilege build/develop)

  # Map of project key => project ARM resource ID, exposed by the landing-zone module.
  foundry_project_ids = module.test.ai_foundry_project_ids
}

# Admin group -> Foundry Owner on each project. Skipped entirely when the
# variable is null.
resource "azurerm_role_assignment" "foundry_project_admin" {
  for_each = var.foundry_admin_entra_group_object_id == null ? {} : local.foundry_project_ids

  scope              = each.value
  role_definition_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.foundry_owner_role_definition_id}"
  principal_id       = var.foundry_admin_entra_group_object_id
  principal_type     = "Group"
}

# Developer group -> Foundry User on each project. Skipped entirely when the
# variable is null.
resource "azurerm_role_assignment" "foundry_project_developer" {
  for_each = var.foundry_ai_developer_entra_group_object_id == null ? {} : local.foundry_project_ids

  scope              = each.value
  role_definition_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.foundry_user_role_definition_id}"
  principal_id       = var.foundry_ai_developer_entra_group_object_id
  principal_type     = "Group"
}
