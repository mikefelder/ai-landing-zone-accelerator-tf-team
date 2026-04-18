# `standalone-foundry-poc` — Standalone Foundry proof-of-concept (BYO VNet)

**Best for:** Organizations that **do not** follow Azure Landing Zone patterns and want a low-cost Azure AI Foundry **proof-of-concept** in an existing subscription, using a VNet they bring themselves.

This blueprint sets `flag_platform_landing_zone = false` so the module owns the private DNS zones and topology, while you bring an existing VNet (no firewall/hub built). It is the quickest path to a self-contained Foundry sandbox and has no dependency on a platform team.
