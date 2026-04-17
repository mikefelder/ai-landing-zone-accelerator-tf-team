variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "azure_resource_developers_group_object_id" {
  type        = string
  description = <<DESCRIPTION
The Entra ID object ID of the security group whose members should have ARM control-plane
access (e.g. Contributor) to the Azure resources within the deployed resource groups.
DESCRIPTION
}

variable "location" {
  type        = string
  default     = "swedencentral"
  description = "The Azure region to deploy resources into."
}


