output "ai_foundry_id" {
  description = "The resource ID of the AI Foundry account."
  value       = module.foundry_ptn.ai_foundry_id
}

output "ai_foundry_name" {
  description = "The name of the AI Foundry account."
  value       = module.foundry_ptn.ai_foundry_name
}

output "ai_foundry_project_ids" {
  description = <<DESCRIPTION
Map of AI Foundry project key (as supplied in `ai_foundry_definition.ai_projects`)
to the project's ARM resource ID. Use these IDs to scope RBAC role assignments at
the individual project level (e.g. Foundry Owner / Foundry User for Entra groups).
DESCRIPTION
  value       = module.foundry_ptn.ai_foundry_project_id
}
