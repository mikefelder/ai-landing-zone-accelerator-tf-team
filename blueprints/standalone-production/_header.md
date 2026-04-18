# Standalone Production blueprint

This blueprint deploys a **complete, self-contained, production-grade** AI/ML Landing Zone into an existing Azure subscription **without any dependency on an Azure Landing Zone**. All supporting platform services — VNet, private DNS zones, firewall/egress, monitoring, APIM, Application Gateway, Bastion, jumpbox — are provisioned as part of the deployment.

## Use case

> **Best fit for:** organizations that do **not** follow Azure Landing Zone patterns and want to deploy the necessary Azure resources to an existing Azure Subscription using this ALZ architecture as a standalone **production-grade** Azure AI Foundry environment.

## What Gets Created

### Networking & platform services (all in-subscription)
- **Spoke VNet** sized for production within `192.168.0.0/16` (required by Foundry capabilityHost network injection)
- **Private DNS zones** for all Azure PaaS services (Key Vault, Storage, Cosmos DB, AI Search, ACR, OpenAI, etc.)
- **Egress controls** — optionally direct-internet via `use_internet_routing = true` (suitable for Application Gateway v2 deployments) or via firewall when integrated
- **Monitoring** — Log Analytics workspace + diagnostic settings across all components

### AI/ML Landing Zone (via root module)
- **AI Foundry Hub** with AI Agent Service and `gpt-4.1` model deployment (GlobalStandard)
- **AI Foundry Project** with connections to Cosmos DB, AI Search, and Storage
- **AI Search**, **Cosmos DB** (Session consistency), **Key Vault**, **Storage Account**
- **Container App Environment**, **Container Registry**, **App Configuration** for GenAI workloads
- **APIM** and **Application Gateway** for production traffic management and ingress
- **Bastion** and **build/jump VM** for operator access
- All supporting resources with private endpoints connected via the spoke VNet

## Design Decisions

- **`flag_platform_landing_zone = false`** — fully standalone; no ALZ hub or platform subscription required.
- **Module-managed VNet** — provisioned by this blueprint (not BYO) and sized for production.
- **Full add-on set enabled** — APIM, Application Gateway, Bastion, jumpbox, and monitoring are all deployed for a production posture.
- **`use_internet_routing` available** — when set to `true`, enables direct-internet egress instead of firewall routing (useful for Application Gateway v2).
- **Random region** — uses `Azure/avm-utl-regions/azurerm` to randomize region selection at deploy time so the blueprint is portable across geos.
