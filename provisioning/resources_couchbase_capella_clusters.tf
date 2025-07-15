resource "couchbase-capella_cluster" "cluster" {
  for_each        = contains(local.couchbase_cluster_env, var.env) ? var.couchbase_clusters_params : {}
  organization_id = lookup(each.value, "org_id", local.couchbase_org_id[var.env])
  project_id      = lookup(each.value, "project_id", couchbase-capella_project.project.0.id)
  name            = "tf-${var.env}-${each.key}-${each.value.cloud_provider.region}"
  description     = lookup(each.value, "description", "")
  support = each.value.support

  couchbase_server = {
    version = "7.6"
  }

  cloud_provider = each.value.cloud_provider
  service_groups = each.value.service_groups

  availability = {
    type = each.value.availability_type
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [couchbase-capella_project.project]
}
