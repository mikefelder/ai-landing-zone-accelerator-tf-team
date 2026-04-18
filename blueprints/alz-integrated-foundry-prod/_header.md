# `alz-integrated-foundry-prod` — ALZ-integrated production-grade Foundry

**Best for:** Organizations that have already adopted Azure Landing Zones (ALZ) and want to deploy a **production-grade** Azure AI Foundry environment into an existing application landing zone subscription, leveraging the ALZ hub for DNS, firewall, and hybrid connectivity.

This blueprint sets `flag_platform_landing_zone = true` and lets the module create the spoke VNet, then peers it back into the ALZ hub via `vnet_peering_configuration` and reuses the hub's private DNS zones. The full Foundry surface is enabled: APIM, App Gateway, Bastion, AI Agent Service, AI projects with connections to Cosmos DB, AI Search, and Storage.
