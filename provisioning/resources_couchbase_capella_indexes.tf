resource "couchbase-capella_query_indexes" "indexes" {
  depends_on      = [couchbase-capella_collection.collection]
  for_each        = local.couchbase_unified_indexes
  cluster_id      = lookup(each.value, "cluster_id", "") != "" ? [for elem in data.couchbase-capella_clusters.clusters.0.data : elem if elem.id == each.value.cluster_id][0].id : couchbase-capella_cluster.cluster[each.value.cluster_name].id
  project_id      = lookup(each.value, "project_id", "") != "" ? [for elem in data.couchbase-capella_clusters.clusters.0.data : elem if elem.id == each.value.cluster_id][0].project_id : couchbase-capella_cluster.cluster[each.value.cluster_name].project_id
  organization_id = lookup(each.value, "organization_id", local.couchbase_org_id[var.env])
  bucket_name     = each.value.bucket
  index_name      = each.value.name
  scope_name      = each.value.scope
  collection_name = each.value.collection
  index_keys      = [each.value.fields]

  with = {
    num_replica = var.env == "prod" ? 1 : 0
  }
}