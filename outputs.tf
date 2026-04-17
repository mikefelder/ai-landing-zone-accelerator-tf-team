#TODO: determine what a good set of outpus should be and update.
output "resource_id" {
  description = "Future resource ID output for the LZA."
  value       = "tbd"
}

output "ks_ai_search_resource_id" {
  description = "The resource ID of the standalone AI Search service."
  value       = var.ks_ai_search_definition.deploy ? module.search_service[0].resource_id : null
}
