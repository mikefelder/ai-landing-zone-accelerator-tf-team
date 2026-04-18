# Blueprints

This directory contains four ready-to-deploy AI/ML Landing Zone **blueprints**, each aligned with a specific organizational use case. Pick the one that best matches your environment and adapt it to your needs.

> **Note:** This directory was previously named `examples/`. A symlink at the repo root preserves backward compatibility with AVM tooling that hard-codes the `examples/` path.

## Authoring conventions

- Create a directory for each blueprint.
- Create a `_header.md` file in each directory to describe the blueprint.
- Run `make fmt && make docs` from the repo root to generate the required documentation.
- If you want a blueprint to be ignored by the end-to-end pipeline, add a `.e2eignore` file to the blueprint directory.
- Blueprints must be deployable and idempotent. Ensure no input variables are required to run them, and use random values (e.g. via the [naming module](https://registry.terraform.io/modules/Azure/naming/azurerm/latest)) to keep resource names unique.

## Choosing a blueprint

Each blueprint is shaped by two independent decisions:

1. **Does your organization already operate an Azure Landing Zone (ALZ)?** This selects between the `alz-integrated-*` blueprints (`flag_platform_landing_zone = true` — assume the platform/connectivity subscriptions already provide the hub VNet, Azure Firewall, DNS Private Resolver, private DNS zones, and hybrid connectivity) and the `standalone-*` blueprints (`flag_platform_landing_zone = false` — the AI landing zone deploys its own supporting platform services).
2. **Is this a proof-of-concept or a production-grade deployment?** PoC blueprints minimize footprint by reusing an existing VNet (`vnet_definition.existing_byo_vnet`), consolidating into a single resource group, and disabling optional add-ons (APIM, Application Gateway, Bastion, jumpbox). Production blueprints provision a dedicated spoke VNet sized for production and enable the full add-on set.

Use the matrix below to pick the right starting point:

| Scenario | Blueprint | Why |
|----------|-----------|-----|
| Org **has** adopted ALZ + networking, deploying a **PoC** Azure AI Foundry into an existing app landing zone subscription | [`alz-integrated-poc`](./alz-integrated-poc) | `flag_platform_landing_zone = true` attaches to the existing hub for DNS / firewall / hybrid connectivity, and `existing_byo_vnet` reuses a spoke VNet from the connectivity team. Single-RG layout, no jumpbox/Bastion/APIM/App Gateway — minimal blast radius and fastest deploy for a PoC. |
| Org **has** adopted ALZ + networking, deploying a **production-grade** Azure AI Foundry into an existing app landing zone subscription | [`alz-integrated-production`](./alz-integrated-production) | `flag_platform_landing_zone = true` integrates with platform-provided hub services (DNS private zones, firewall egress, hybrid connectivity), while the module provisions a dedicated, properly sized spoke VNet and the full production add-on set (APIM, Application Gateway, Bastion, jumpbox, monitoring). |
| Org does **not** follow ALZ patterns, deploying a standalone **PoC** AI Foundry into an existing Azure subscription | [`standalone-poc`](./standalone-poc) | `flag_platform_landing_zone = false` deploys all required supporting services (private DNS zones, monitoring, etc.) inside the same subscription, while `existing_byo_vnet` reuses a VNet you already have. Smallest standalone footprint — ideal for a PoC where you don't want to introduce new networking. |
| Org does **not** follow ALZ patterns, deploying a standalone **production-grade** AI Foundry into an existing Azure subscription | [`standalone-production`](./standalone-production) | `flag_platform_landing_zone = false` provisions a complete, self-contained AI landing zone — VNet, private DNS zones, firewall/egress, monitoring, APIM, Application Gateway, Bastion, jumpbox — without any dependency on a platform landing zone. Suitable as a production baseline when no ALZ exists. |

> **Tip:** Start from the blueprint closest to your target topology, then trim or extend the optional `*_definition` blocks (APIM, App Gateway, Bastion, jumpbox, etc.) to match your requirements. Toggling those blocks off is the single biggest lever for shortening deployment time in PoC scenarios.

## Application Gateway v2 Internet Routing

The `standalone-production` blueprint demonstrates the use of the `use_internet_routing` variable which enables direct internet routing instead of firewall routing when `flag_platform_landing_zone = false`. This is particularly useful for Azure Application Gateway v2 deployments that require direct internet connectivity and cannot use virtual appliance routing.
