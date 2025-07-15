resource "couchbase-capella_collection" "collection" {
  for_each        = local.couchbase_capella_unified_collection_config
  bucket_id       = lookup(each.value, "bucket_id", couchbase-capella_bucket.bucket[each.value.bucket_name].id)
  cluster_id      = lookup(each.value, "cluster_id", "") != "" ? [for elem in data.couchbase-capella_clusters.clusters.0.data : elem if elem.id == each.value.cluster_id][0].id : couchbase-capella_cluster.cluster[each.value.cluster_name].id
  project_id      = lookup(each.value, "project_id", "") != "" ? [for elem in data.couchbase-capella_clusters.clusters.0.data : elem if elem.id == each.value.cluster_id][0].project_id : couchbase-capella_cluster.cluster[each.value.cluster_name].project_id
  collection_name = each.value.name
  max_ttl         = lookup(each.value, "max_ttl", "-1")
  organization_id = lookup(each.value, "organization_id", local.couchbase_org_id[var.env])
  scope_name      = each.value.scope_name

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [couchbase-capella_scope.scopes]
}