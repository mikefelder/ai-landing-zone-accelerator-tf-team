terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116, < 5.0"
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

locals {
  location = var.location
}

data "azurerm_client_config" "current" {}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.9.2"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# Get the deployer IP address to allow for public write to the key vault. This is to make sure the tests run.
# In practice your deployer machine will be on a private network and this will not be required.
data "http" "ip" {
  url = "https://api.ipify.org/"
  retry {
    attempts     = 5
    max_delay_ms = 1000
    min_delay_ms = 500
  }
}

# Single resource group for all resources
resource "azurerm_resource_group" "this" {
  location = local.location
  name     = "rg-foundry-poc"
}

#create a sample hub to mimic an existing network landing zone configuration
module "example_hub" {
  source = "../../modules/example_hub_vnet"

  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  vnet_definition = {
    address_space = "10.10.0.0/24"
  }
  bastion_definition = {
    deploy = false
  }
  deployer_ip_address        = "${data.http.ip.response_body}/32"
  enable_telemetry           = var.enable_telemetry
  existing_resource_group_id = azurerm_resource_group.this.id
  jump_vm_definition = {
    deploy = false
  }
  name_prefix = "${module.naming.resource_group.name_unique}-hub"
}

#create a BYO vnet and peer to the hub
module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.16.0"

  location      = azurerm_resource_group.this.location
  parent_id     = azurerm_resource_group.this.id
  address_space = ["192.168.0.0/20"] # has to be out of 192.168.0.0/16 currently. Other RFC1918 not supported for foundry capabilityHost injection.
  dns_servers = {
    dns_servers = [for key, value in module.example_hub.dns_resolver_inbound_ip_addresses : value]
  }
  name = module.naming.virtual_network.name_unique
  #name = "ai-lz-vnet-default-2"
  peerings = {
    peertovnet1 = {
      name                                 = "peering-vnet2-to-vnet1"
      remote_virtual_network_resource_id   = module.example_hub.virtual_network_resource_id
      allow_forwarded_traffic              = true
      allow_gateway_transit                = true
      allow_virtual_network_access         = true
      create_reverse_peering               = true
      reverse_name                         = "peering-vnet1-to-vnet2"
      reverse_allow_virtual_network_access = true
    }
  }
}

import {
  to = module.test.azurerm_resource_group.this
  id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/rg-foundry-poc"
}

module "test" {
  source = "../../"

  location            = local.location
  resource_group_name = azurerm_resource_group.this.name
  vnet_definition = {
    existing_byo_vnet = {
      this_vnet = {
        vnet_resource_id = module.vnet.resource_id
      }
    }
  }
  ai_foundry_definition = {
    purge_on_destroy = true
    ai_foundry = {
      create_ai_agent_service    = true
      enable_diagnostic_settings = false
      role_assignments = {
        azure_resource_developers_foundry = {
          role_definition_id_or_name = "Azure AI Developer"
          principal_id               = var.azure_resource_developers_group_object_id
          principal_type             = "Group"
          description                = "Grants Foundry data-plane access to the Azure Resource Developers group (also has ARM access)"
        }
      }
    }
    ai_model_deployments = {
      "gpt-4.1" = {
        name = "gpt-4.1"
        model = {
          format  = "OpenAI"
          name    = "gpt-4.1"
          version = "2025-04-14"
        }
        scale = {
          type     = "GlobalStandard"
          capacity = 1
        }
      }
    }
    ai_projects = {
      project_1 = {
        name                       = "default-project-1"
        description                = "Project 1 description"
        display_name               = "Project 1 Display Name"
        create_project_connections = true
        cosmos_db_connection = {
          new_resource_map_key = "this"
        }
        ai_search_connection = {
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
        consistency_level = "Session"
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
    deploy          = false
    publisher_email = "DoNotReply@exampleEmail.com"
    publisher_name  = "Azure API Management"
  }
  app_gateway_definition = {
    deploy = false
    backend_address_pools = {
      placeholder = { name = "placeholder" }
    }
    backend_http_settings = {
      placeholder = { name = "placeholder", port = 80, protocol = "Http" }
    }
    frontend_ports = {
      placeholder = { name = "placeholder", port = 80 }
    }
    http_listeners = {
      placeholder = { name = "placeholder", frontend_port_name = "placeholder" }
    }
    request_routing_rules = {
      placeholder = { name = "placeholder", rule_type = "Basic", http_listener_name = "placeholder", backend_address_pool_name = "placeholder", backend_http_settings_name = "placeholder", priority = 100 }
    }
  }
  bastion_definition = {
    deploy = false
  }
  container_app_environment_definition = {
    enable_diagnostic_settings = false
  }
  enable_telemetry           = var.enable_telemetry
  flag_platform_landing_zone = true
  genai_app_configuration_definition = {
    enable_diagnostic_settings = false
    role_assignments = {
      azure_resource_developers = {
        role_definition_id_or_name = "App Configuration Data Reader"
        principal_id               = var.azure_resource_developers_group_object_id
        principal_type             = "Group"
        description                = "Grants App Configuration read access to the Azure Resource Developers group"
      }
    }
  }
  genai_container_registry_definition = {
    enable_diagnostic_settings = false
    role_assignments = {
      azure_resource_developers = {
        role_definition_id_or_name = "AcrPush"
        principal_id               = var.azure_resource_developers_group_object_id
        principal_type             = "Group"
        description                = "Grants container registry push/pull access to the Azure Resource Developers group"
      }
    }
  }
  genai_cosmosdb_definition = {
    consistency_level = "Session"
  }
  genai_key_vault_definition = {
    #this is for AVM testing purposes only. Doing this as we don't have an easy for the test runner to be privately connected for testing.
    public_network_access_enabled = true
    network_acls = {
      bypass   = "AzureServices"
      ip_rules = ["${data.http.ip.response_body}/32"]
    }
    role_assignments = {
      azure_resource_developers = {
        role_definition_id_or_name = "Key Vault Secrets User"
        principal_id               = var.azure_resource_developers_group_object_id
        principal_type             = "Group"
        description                = "Grants Key Vault secrets read access to the Azure Resource Developers group"
      }
    }
  }
  genai_storage_account_definition = {
    role_assignments = {
      azure_resource_developers = {
        role_definition_id_or_name = "Storage Blob Data Contributor"
        principal_id               = var.azure_resource_developers_group_object_id
        principal_type             = "Group"
        description                = "Grants blob storage data access to the Azure Resource Developers group"
      }
    }
  }
  jumpvm_definition = {
    deploy = false
  }
  ks_ai_search_definition = {
    enable_diagnostic_settings = false
    role_assignments = {
      azure_resource_developers = {
        role_definition_id_or_name = "Search Index Data Contributor"
        principal_id               = var.azure_resource_developers_group_object_id
        principal_type             = "Group"
        description                = "Grants AI Search index data access to the Azure Resource Developers group"
      }
    }
  }
  private_dns_zones = {
    existing_zones_resource_group_resource_id = module.example_hub.resource_group_resource_id
  }
  tags = {
    SecurityControl = "Ignore"
  }
}
