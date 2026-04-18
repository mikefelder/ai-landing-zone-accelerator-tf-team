# Examples

- Create a directory for each example.
- Create a `_header.md` file in each directory to describe the example.
- See the `default` example provided as a skeleton - this must remain, but you can add others.
- Run `make fmt && make docs` from the repo root to generate the required documentation.
- If you want an example to be ignored by the end to end pipeline add a `.e2eignore` file to the example directory.

## Choosing an example

Each example is shaped by two independent decisions:

1. **Does your organization already operate an Azure Landing Zone (ALZ)?** This selects between the `default*` examples (`flag_platform_landing_zone = true` — assume the platform/connectivity subscriptions already provide the hub VNet, Azure Firewall, DNS Private Resolver, private DNS zones, and hybrid connectivity) and the `standalone*` examples (`flag_platform_landing_zone = false` — the AI landing zone deploys its own supporting platform services).
2. **Are you bringing your own VNet, or letting the module create one?** The `*-byo-vnet` variants reference an existing spoke VNet via `vnet_definition.existing_byo_vnet`, which is lighter weight and well-suited to PoCs running inside an already-provisioned subscription. The non-BYO variants create a fresh spoke VNet sized for production use and provision the full set of optional add-ons (APIM, Application Gateway, Bastion, jumpbox, etc.).

Use the matrix below to pick the right starting point:

| Scenario | Recommended example | Why |
|----------|---------------------|-----|
| Org **has** adopted ALZ + networking, deploying a **PoC** Azure AI Foundry into an existing app landing zone subscription | [`default-byo-vnet`](./default-byo-vnet) | `flag_platform_landing_zone = true` attaches to the existing hub for DNS / firewall / hybrid connectivity, and `existing_byo_vnet` reuses a spoke VNet from the connectivity team. Single-RG layout, no jumpbox/Bastion/APIM/App Gateway — minimal blast radius and fastest deploy for a PoC. |
| Org **has** adopted ALZ + networking, deploying a **production-grade** Azure AI Foundry into an existing app landing zone subscription | [`default`](./default) | `flag_platform_landing_zone = true` integrates with platform-provided hub services (DNS private zones, firewall egress, hybrid connectivity), while the module provisions a dedicated, properly sized spoke VNet and the full production add-on set (APIM, Application Gateway, Bastion, jumpbox, monitoring). |
| Org does **not** follow ALZ patterns, deploying a standalone **PoC** AI Foundry into an existing Azure subscription | [`standalone-byo-vnet`](./standalone-byo-vnet) | `flag_platform_landing_zone = false` deploys all required supporting services (private DNS zones, monitoring, etc.) inside the same subscription, while `existing_byo_vnet` reuses a VNet you already have. Smallest standalone footprint — ideal for a PoC where you don't want to introduce new networking. |
| Org does **not** follow ALZ patterns, deploying a standalone **production-grade** AI Foundry into an existing Azure subscription | [`standalone`](./standalone) | `flag_platform_landing_zone = false` provisions a complete, self-contained AI landing zone — VNet, private DNS zones, firewall/egress, monitoring, APIM, Application Gateway, Bastion, jumpbox — without any dependency on a platform landing zone. Suitable as a production baseline when no ALZ exists. |

> **Tip:** Start from the example closest to your target topology, then trim or extend the optional `*_definition` blocks (APIM, App Gateway, Bastion, jumpbox, etc.) to match your requirements. Toggling those blocks off is the single biggest lever for shortening deployment time in PoC scenarios.

## Application Gateway v2 Internet Routing

The `standalone` example demonstrates the use of the `use_internet_routing` variable which enables direct internet routing instead of firewall routing when `flag_platform_landing_zone = false`. This is particularly useful for Azure Application Gateway v2 deployments that require direct internet connectivity and cannot use virtual appliance routing.

> **Note:** Examples must be deployable and idempotent. Ensure that no input variables are required to run the example and that random values are used to ensure unique resource names. E.g. use the [naming module](https://registry.terraform.io/modules/Azure/naming/azurerm/latest) to generate a unique name for a resource.
