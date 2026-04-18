# Blueprints

This directory contains four opinionated, deployable **blueprints** that demonstrate how to consume the `terraform-azurerm-avm-ptn-aiml-landing-zone` pattern module for the most common organizational scenarios.

> **Note:** This folder is named `blueprints/` (renamed from the upstream AVM convention `examples/`). The four subdirectories below are still consumed by AVM CI tooling that expects standalone, deployable Terraform root modules — each blueprint must be deployable and idempotent without requiring user-supplied input variables.

## Choose a blueprint

| Organization profile | Blueprint | `flag_platform_landing_zone` | Networking | Surface |
|---|---|---|---|---|
| ALZ adopted, existing subscription, **POC** | [`alz-integrated-foundry-poc`](alz-integrated-foundry-poc/) | `true` | BYO spoke VNet from the platform team | Minimal — APIM, App Gateway, Bastion, jump VM disabled |
| ALZ adopted, existing subscription, **production-grade Foundry** | [`alz-integrated-foundry-prod`](alz-integrated-foundry-prod/) | `true` | Module creates spoke VNet + peers it back to the ALZ hub | Full — APIM (with sample APIs), App Gateway, Bastion, AI Agent Service, AI projects with connections |
| No ALZ, existing subscription, **standalone POC** | [`standalone-foundry-poc`](standalone-foundry-poc/) | `false` | BYO VNet (no hub/firewall built) | Module-owned private DNS zones; no firewall/UDR |
| No ALZ, existing subscription, **standalone production-grade Foundry** | [`standalone-foundry-prod`](standalone-foundry-prod/) | `false` | Module-owned VNet + Azure Firewall, firewall policy, UDR | Full — Bastion, build VM, APIM, App Gateway, AI Search, private DNS |

## Authoring rules

- One subdirectory per blueprint; each is a standalone Terraform root module.
- Each subdirectory must contain a `_header.md` describing the blueprint.
- Run `make fmt && make docs` from the repo root to regenerate `README.md` files.
- Add a `.e2eignore` file to a blueprint directory to exclude it from the end-to-end pipeline.
- Blueprints must be deployable and idempotent — no required input variables, use the [naming module](https://registry.terraform.io/modules/Azure/naming/azurerm/latest) for unique resource names.

## Application Gateway v2 internet routing

The [`standalone-foundry-prod`](standalone-foundry-prod/) blueprint demonstrates the `use_internet_routing` variable, which enables direct internet routing instead of firewall routing when `flag_platform_landing_zone = false`. Useful for Application Gateway v2 deployments that require direct internet connectivity and cannot use virtual-appliance routing.
# Examples

- Create a directory for each example.
- Create a `_header.md` file in each directory to describe the example.
- See the `default` example provided as a skeleton - this must remain, but you can add others.
- Run `make fmt && make docs` from the repo root to generate the required documentation.
- If you want an example to be ignored by the end to end pipeline add a `.e2eignore` file to the example directory.

## Application Gateway v2 Internet Routing

The `standalone` example demonstrates the use of the `use_internet_routing` variable which enables direct internet routing instead of firewall routing when `flag_platform_landing_zone = false`. This is particularly useful for Azure Application Gateway v2 deployments that require direct internet connectivity and cannot use virtual appliance routing.

> **Note:** Examples must be deployable and idempotent. Ensure that no input variables are required to run the example and that random values are used to ensure unique resource names. E.g. use the [naming module](https://registry.terraform.io/modules/Azure/naming/azurerm/latest) to generate a unique name for a resource.
