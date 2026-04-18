# terraform-azurerm-avm-ptn-aiml-landing-zone — TEAM Inc Accelerator

> **Fork** of [Azure/terraform-azurerm-avm-ptn-aiml-landing-zone](https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-landing-zone) customized for TEAM Inc's AI Landing Zone PoC deployment.

This pattern module creates the full AI landing zone for foundry. For more details on AI Landing Zones please see the [AI Landing Zone documentation](https://aka.ms/ailz/website) including the deployment guide for terraform deployments: [AI Landing Zone Terraform Deployment Guide](https://azure.github.io/AI-Landing-Zones/terraform/).

## TEAM Inc PoC customizations

| Decision | Setting |
|----------|---------|
| Target subscription | App Landing Zone subscription within existing ALZ |
| Networking | BYO VNet from the connectivity subscription (must be `192.168.0.0/16`, minimum `/20`) |
| Jumpbox / Bastion | Disabled — access is RBAC-only, no jump host required |
| RBAC — Azure resources | Entra security group with granular data-plane roles on each resource |
| RBAC — Foundry (ai.azure.com) | Same group gets `Azure AI Developer` on the AI Foundry Hub |
| Recommended blueprint | [`blueprints/alz-integrated-foundry-poc`](blueprints/alz-integrated-foundry-poc/) |

## Blueprints

Ready-to-deploy blueprints for the most common organizational scenarios live under [`blueprints/`](blueprints/):

| Organization profile | Blueprint |
|---|---|
| ALZ adopted, existing subscription, **POC** | [`blueprints/alz-integrated-foundry-poc`](blueprints/alz-integrated-foundry-poc/) |
| ALZ adopted, existing subscription, **production-grade Foundry** | [`blueprints/alz-integrated-foundry-prod`](blueprints/alz-integrated-foundry-prod/) |
| No ALZ, existing subscription, **standalone POC** | [`blueprints/standalone-foundry-poc`](blueprints/standalone-foundry-poc/) |
| No ALZ, existing subscription, **standalone production-grade Foundry** | [`blueprints/standalone-foundry-prod`](blueprints/standalone-foundry-prod/) |
