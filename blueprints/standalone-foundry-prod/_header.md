# `standalone-foundry-prod` — Standalone production-grade Foundry

**Best for:** Organizations that **do not** follow Azure Landing Zone patterns and want a **production-grade** Azure AI Foundry environment in an existing subscription, using this module to build a hub-like landing zone for them.

This blueprint sets `flag_platform_landing_zone = false` and deploys the full module-owned VNet plus **Azure Firewall, firewall policy, and UDR**, private DNS zones, Bastion, build VM, APIM, App Gateway, and AI Search. Use this when there is no enterprise ALZ and you need production-grade controls end-to-end.
