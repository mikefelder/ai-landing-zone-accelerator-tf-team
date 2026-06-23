# `alz-integrated-foundry-prod` — ALZ-integrated production-grade Foundry

**Best for:** Organizations that have already adopted Azure Landing Zones (ALZ) and want to deploy a **production-grade** Azure AI Foundry environment into an existing application landing zone subscription, leveraging the ALZ hub for DNS, firewall, and hybrid connectivity.

This blueprint sets `flag_platform_landing_zone = true` and lets the module create the spoke VNet, then peers it back into the ALZ hub via `vnet_peering_configuration` and reuses the hub's private DNS zones. The Foundry core is deployed with the AI Agent Service enabled and AI projects connected to AI Search and Storage. APIM, Application Gateway, Bastion, the Container App environment, the GenAI app-resource tier (App Configuration, Container Registry, Cosmos DB), and the knowledge-source services (AI Search, Bing grounding) are disabled by default — turn them on per environment as needed.

## Target subscription

This blueprint **targets a subscription that already exists** — it does not vend one. Have your platform team create the landing zone subscription first (Azure portal, your ALZ subscription-vending pipeline, or the [`Azure/avm-ptn-alz-sub-vending/azure`](https://registry.terraform.io/modules/Azure/avm-ptn-alz-sub-vending/azure/latest) module run from a platform repo). Then point this deployment at it in one of two ways:

- Set `subscription_id` (and optionally `tenant_id`) in your `*.tfvars`, or
- Export `ARM_SUBSCRIPTION_ID` (and `ARM_TENANT_ID`) so CI/CD injects the target without editing the blueprint.

Keeping subscription creation out of this configuration avoids the billing-scope permissions and two-phase `apply` that in-line vending requires, and gives the workload a clean single-`apply` deploy and destroy lifecycle.

## Networking — /24 address space

The spoke VNet uses the infra-allocated `/24` (`172.20.115.0/24`) with explicit subnet prefixes. The two `Microsoft.App/environments`-delegated subnets (`AIFoundrySubnet`, `ContainerAppEnvironmentSubnet`) are pinned to `/27`, Azure's minimum for delegated subnets. All three RFC1918 ranges (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) are supported for the Foundry agent capabilityHost subnet; `172.20.115.0/24` falls within `172.16.0.0/12`. Microsoft recommends a `/24` for the agent subnet alone, so move to a `/23` VNet if Agent Service / Container Apps scaling needs more headroom than the `/27` provides.
