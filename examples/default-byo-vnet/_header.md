# Default BYO VNet example — TEAM Inc PoC

This example deploys the AI/ML Landing Zone into an existing **App Landing Zone subscription** within a Microsoft Azure Landing Zone (ALZ) architecture. It is configured for TEAM Inc's PoC with the following design decisions:

- **`flag_platform_landing_zone = true`** — assumes the connectivity and platform subscriptions already provide hub networking, DNS private zones, firewalls, and hybrid connectivity.
- **Bring Your Own VNet** — references a spoke VNet pre-provisioned by the platform/infra team via `existing_byo_vnet`. The VNet **must** use an address space within `192.168.0.0/16` (required by the Foundry capabilityHost network injection). The infra team should provision at least a `/20`.
- **No jumpbox or bastion** — both are explicitly disabled (`deploy = false`). Developer access to Azure resources is via RBAC only.
- **RBAC** — an Entra ID security group (`azure_resource_developers_group_object_id`) is assigned:
  - `Azure AI Developer` on the AI Foundry Hub (data-plane access to ai.azure.com)
  - Granular data-plane roles on each supporting resource (Key Vault, Storage, ACR, App Config, AI Search)
