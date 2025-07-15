data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "couchbase-capella_clusters" "clusters" {
  count           = lookup(local.couchbase_manual_clusters_id, var.env, "") != "" ? 1 : 0
  organization_id = local.couchbase_org_id[var.env]
  project_id      = var.couchbase_default_project_id
}