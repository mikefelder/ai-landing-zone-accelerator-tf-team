# ALZ-Integrated PoC blueprint — TEAM Inc

This blueprint deploys the AI/ML Landing Zone into a **single resource group** (`rg-foundry-poc`) within an Azure Landing Zone (ALZ) architecture. It is configured for TEAM Inc's PoC with the following design decisions:

## Use case

> **Best fit for:** organizations that have already adopted Azure Landing Zone patterns and networking, and want to leverage this ALZ architecture to deploy resources to an existing Azure Subscription for an Azure AI Foundry **proof-of-concept**.

## Resource Group Strategy

All resources are consolidated into one resource group (`rg-foundry-poc`). The example creates the RG first, then passes it to both the hub networking module (via `existing_resource_group_id`) and the main AI/ML landing zone module (via a Terraform `import` block so both share the same RG without conflict).

## What Gets Created

### Hub Networking (via `example_hub_vnet` module)
- **Hub VNet** (`10.10.0.0/24`) with subnets for Azure Firewall and DNS Resolver
- **Azure Firewall** (Standard SKU) with permissive outbound rules for RFC 1918 traffic
- **NAT Gateway** with a public IP
- **DNS Private Resolver** with an inbound endpoint (provides DNS resolution for private endpoints)
- **Private DNS Zones** for all Azure PaaS services (Key Vault, Storage, Cosmos DB, AI Search, ACR, OpenAI, etc.) linked to the hub VNet
- **NSG** on the DNS Resolver subnet (required by Azure Policy)
- **Log Analytics Workspace** for firewall diagnostics

### Spoke VNet (BYO pattern)
- **Spoke VNet** (`192.168.0.0/20`) peered bidirectionally with the hub VNet
- DNS servers pointed at the hub's DNS Private Resolver inbound IP
- Address space within `192.168.0.0/16` (required by Foundry capabilityHost network injection)

### AI/ML Landing Zone (via root module)
- **AI Foundry Hub** with AI Agent Service and a `gpt-4.1` model deployment (GlobalStandard)
- **AI Foundry Project** with connections to Cosmos DB, AI Search, and Storage
- **AI Search**, **Cosmos DB** (Session consistency), **Key Vault**, **Storage Account**
- **Container App Environment** for GenAI workloads
- **Container Registry**, **App Configuration**, additional Key Vault and Storage for GenAI apps
- All supporting resources with private endpoints connected via the spoke VNet

## Design Decisions

- **`flag_platform_landing_zone = true`** — assumes the connectivity and platform subscriptions already provide hub networking, DNS private zones, firewalls, and hybrid connectivity.
- **Bring Your Own VNet** — references a spoke VNet pre-provisioned by the platform/infra team via `existing_byo_vnet`.
- **No jumpbox or bastion** — both are explicitly disabled (`deploy = false`). Developer access to Azure resources is via RBAC only.
- **No APIM or App Gateway** — both disabled for this PoC.
- **RBAC** — an Entra ID security group (`azure_resource_developers_group_object_id`) is assigned:
  - `Azure AI Developer` on the AI Foundry Hub (data-plane access to ai.azure.com)
  - Granular data-plane roles on each supporting resource (Key Vault, Storage, ACR, App Config, AI Search)
- **Region** — deploys to `swedencentral`.
