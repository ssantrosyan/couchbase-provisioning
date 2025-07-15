resource "couchbase-capella_bucket" "bucket" {
  depends_on              = [couchbase-capella_cluster.cluster]
  for_each                = local.couchbase_capella_filtered_bucket_config
  name                    = each.key
  cluster_id              = lookup(each.value, "cluster_id", "") != "" ? [for elem in data.couchbase-capella_clusters.clusters.0.data : elem if elem.id == each.value.cluster_id][0].id : couchbase-capella_cluster.cluster[each.value.cluster_name].id
  project_id              = lookup(each.value, "project_id", "") != "" ? [for elem in data.couchbase-capella_clusters.clusters.0.data : elem if elem.id == each.value.cluster_id][0].project_id : couchbase-capella_cluster.cluster[each.value.cluster_name].project_id
  organization_id         = lookup(each.value, "organization_id", local.couchbase_org_id[var.env])
  memory_allocation_in_mb = lookup(each.value, "memory_allocation_in_mb")
  replicas                = lookup(each.value, "replicas")[var.env]
  type                    = each.value.type
  storage_backend         = lookup(each.value, "storage_backend", null)
  lifecycle {
    prevent_destroy = true
  }
}