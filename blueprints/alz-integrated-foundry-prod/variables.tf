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

variable "foundry_admin_entra_group_object_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Object (principal) ID of the Microsoft Entra security group that should receive
**Foundry Owner** (admin) access on every AI Foundry project in this blueprint.

Foundry Owner grants full management of projects and resources plus the data-plane
permissions needed to build and develop. The assignment is scoped to each project
resource (not the account), and is created with `principal_type = "Group"`.

Leave `null` to skip the admin role assignment. Provide the group's object ID, e.g.
via `TF_VAR_foundry_admin_entra_group_object_id`.
DESCRIPTION

  validation {
    condition     = var.foundry_admin_entra_group_object_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", coalesce(var.foundry_admin_entra_group_object_id, "x")))
    error_message = "foundry_admin_entra_group_object_id must be a valid GUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) or null."
  }
}

variable "foundry_ai_developer_entra_group_object_id" {
  type        = string
  default     = null
  description = <<DESCRIPTION
Object (principal) ID of the Microsoft Entra security group that should receive
**Foundry User** (developer) access on every AI Foundry project in this blueprint.

Foundry User is the least-privilege Foundry data-plane role for building and
developing within a project. It is the correct Foundry equivalent of the legacy
"Azure AI Developer" role, which Microsoft documents as *not* intended for Foundry
resources. The assignment is scoped to each project resource (not the account), and
is created with `principal_type = "Group"`.

Leave `null` to skip the developer role assignment. Provide the group's object ID,
e.g. via `TF_VAR_foundry_ai_developer_entra_group_object_id`.
DESCRIPTION

  validation {
    condition     = var.foundry_ai_developer_entra_group_object_id == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", coalesce(var.foundry_ai_developer_entra_group_object_id, "x")))
    error_message = "foundry_ai_developer_entra_group_object_id must be a valid GUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) or null."
  }
}
