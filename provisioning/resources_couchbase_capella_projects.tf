resource "couchbase-capella_project" "project" {
  count           = contains(local.couchbase_project_env, var.env) ? 1 : 0
  organization_id = local.couchbase_org_id[var.env]
  name            = local.env_naming_dict[var.env]
  description     = "Company ${var.env} cluster"

  lifecycle {
    prevent_destroy = true
  }
}