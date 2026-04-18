# ALZ-Integrated Production blueprint

This blueprint deploys a **production-grade** AI/ML Landing Zone into an existing Azure subscription that already participates in an Azure Landing Zone (ALZ) architecture. The platform/connectivity subscriptions are assumed to provide the hub networking, DNS private zones, firewalls, and hybrid connectivity; the AI landing zone attaches to that hub.

## Use case

> **Best fit for:** organizations that have already adopted Azure Landing Zone patterns and networking, and want to leverage this ALZ architecture to deploy a **production-grade** Azure AI Foundry environment to an existing Azure Subscription.

## What Gets Created

### Hub integration (assumed pre-existing)
- Hub VNet, Azure Firewall, DNS Private Resolver, private DNS zones, and hybrid connectivity are **assumed to already exist** in the connectivity subscription and are referenced via the platform landing zone integration.

### Spoke VNet (module-managed)
- A dedicated **spoke VNet** is created and peered to the hub. Address space is sized for production workloads (within `192.168.0.0/16` as required by Foundry capabilityHost network injection).

### AI/ML Landing Zone (via root module)
- **AI Foundry Hub** with AI Agent Service and `gpt-4.1` model deployment (GlobalStandard)
- **AI Foundry Project** with connections to Cosmos DB, AI Search, and Storage
- **AI Search**, **Cosmos DB**, **Key Vault**, **Storage Account**
- **Container App Environment**, **Container Registry**, **App Configuration** for GenAI workloads
- **APIM** and **Application Gateway** for production traffic management and ingress
- **Bastion** and **build/jump VM** for operator access
- **Monitoring** (Log Analytics + diagnostic settings) across all components
- All supporting resources with private endpoints connected via the spoke VNet

## Design Decisions

- **`flag_platform_landing_zone = true`** — relies on the platform-provided hub for DNS, firewall egress, and hybrid connectivity.
- **Module-managed spoke VNet** — provisioned and peered by this blueprint (not BYO).
- **Full add-on set enabled** — APIM, Application Gateway, Bastion, jumpbox, monitoring are all deployed for a production posture.
- **Random region** — uses `Azure/avm-utl-regions/azurerm` to randomize region selection at deploy time so the blueprint is portable across geos.
