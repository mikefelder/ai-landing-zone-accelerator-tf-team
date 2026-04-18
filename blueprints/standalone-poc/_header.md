# Standalone PoC blueprint

This blueprint deploys an AI/ML Landing Zone into an existing Azure subscription **without any dependency on an Azure Landing Zone**. It reuses an existing VNet (BYO) to keep the footprint minimal — ideal for a proof-of-concept in an organization that does not (yet) follow ALZ patterns.

## Use case

> **Best fit for:** organizations that do **not** follow Azure Landing Zone patterns and want to deploy the necessary Azure resources to an existing Azure Subscription using this ALZ architecture as a standalone **proof-of-concept** environment.

## What Gets Created

### Spoke VNet (BYO pattern)
- References an **existing VNet** (provisioned by this blueprint for the test, but typically pre-provisioned by you) within `192.168.0.0/16` as required by Foundry capabilityHost network injection.

### AI/ML Landing Zone (via root module)
- **AI Foundry Hub** with AI Agent Service and `gpt-4.1` model deployment (GlobalStandard)
- **AI Foundry Project** with connections to Cosmos DB, AI Search, and Storage
- **AI Search**, **Cosmos DB** (Session consistency), **Key Vault**, **Storage Account**
- **Private DNS zones** for all PaaS services (provisioned in-subscription since there is no platform hub)
- **Container App Environment**, **Container Registry**, **App Configuration** for GenAI workloads
- All supporting resources with private endpoints connected via the BYO VNet

## Design Decisions

- **`flag_platform_landing_zone = false`** — no ALZ dependency; all supporting platform services are deployed as part of this blueprint.
- **Bring Your Own VNet** — uses `vnet_definition.existing_byo_vnet` to attach to an existing spoke VNet, minimizing the footprint introduced by the PoC.
- **Optional add-ons disabled where appropriate** — toggle `apim_definition`, `app_gateway_definition`, `bastion_definition`, jumpbox, and build VM to suit your PoC scope. Disabling unused add-ons is the single biggest lever for reducing deployment time.
