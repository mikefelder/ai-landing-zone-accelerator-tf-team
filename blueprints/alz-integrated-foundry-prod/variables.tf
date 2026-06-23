variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "subscription_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
The ID of the target Azure subscription to deploy this landing zone into.

This blueprint expects the landing zone subscription to already exist — vend it
separately via your platform team's ALZ process (portal, ALZ pipeline, or the
`Azure/avm-ptn-alz-sub-vending/azure` module run from a platform repo), then point
this deployment at it by setting this value.

When left `null`, the provider falls back to the `ARM_SUBSCRIPTION_ID` environment
variable (or the Azure CLI's active subscription), so CI/CD can inject the target
subscription without editing this file.
DESCRIPTION

  validation {
    condition     = var.subscription_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", coalesce(var.subscription_id, "x")))
    error_message = "subscription_id must be a valid GUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) or null."
  }
}

variable "tenant_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
The ID of the Azure Entra ID tenant the target subscription belongs to.

When left `null`, the provider falls back to the `ARM_TENANT_ID` environment
variable (or the Azure CLI's active tenant). Only set this when deploying across
tenants or when the deploy identity has access to multiple tenants.
DESCRIPTION
}

variable "anthropic_organization_name" {
  type        = string
  description = <<DESCRIPTION
Legal entity name for the Anthropic Claude Marketplace attestation
(`modelProviderData.organizationName`). This value is required and has no
default — applying the deployment auto-accepts the Anthropic Marketplace offer
terms on behalf of this organization, so set it to the legal entity that will
use the Claude models. Review <https://www.anthropic.com/legal/commercial-terms>
before deploying.
DESCRIPTION
}

variable "anthropic_country_code" {
  type        = string
  default     = "US"
  description = "Two-letter ISO country code for the Anthropic Marketplace attestation (`modelProviderData.countryCode`)."

  validation {
    condition     = length(var.anthropic_country_code) == 2
    error_message = "anthropic_country_code must be a 2-letter ISO country code (e.g. US, GB, DE)."
  }
}

variable "anthropic_industry" {
  type        = string
  default     = "technology"
  description = "Industry for the Anthropic Marketplace attestation (`modelProviderData.industry`). Must be a lowercase value supported by Foundry."

  validation {
    condition     = contains(["technology", "finance", "healthcare", "education", "retail", "manufacturing", "government", "media", "other"], var.anthropic_industry)
    error_message = "anthropic_industry must be one of: technology, finance, healthcare, education, retail, manufacturing, government, media, other."
  }
}
