locals {
  couchbase_indexes = {
    index1_name = {
      name         = "index1_name"
      bucket       = "bucket1"
      scope        = "scope1"
      collection   = "collection1"
      fields       = "index_field"
      cluster_name = local.couchbase_cluster_name
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
    index2_name = {
      name         = "index2_name"
      bucket       = "bucket2"
      scope        = "scope2"
      collection   = "collection2"
      fields       = "index_field"
      cluster_name = local.couchbase_cluster_name
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
  }
  couchbase_indexes_stage = {
    index1_name_stage = {
      name         = "index1_name"
      bucket       = "bucket1_stage"
      scope        = "scope1"
      collection   = "collection1"
      fields       = "index_field"
      cluster_name = local.couchbase_cluster_name
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
    index2_name_stage = {
      name         = "index2_name"
      bucket       = "bucket2_stage"
      scope        = "scope2"
      collection   = "collection2"
      fields       = "index_field"
      cluster_name = local.couchbase_cluster_name
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
  }

  couchbase_all_indexes = merge(
    local.couchbase_indexes,
    local.couchbase_indexes_stage
  )

  couchbase_dev_index_keys   = keys(local.couchbase_indexes)
  couchbase_stage_index_keys = keys(local.couchbase_indexes_stage)
  couchbase_prod_index_keys  = keys(local.couchbase_indexes)

  couchbase_unified_indexes = {
    for key, config in local.couchbase_all_indexes :
    key => config
    if contains(
      var.env == "dev" ? local.couchbase_dev_index_keys :
      var.env == "stage" ? local.couchbase_stage_index_keys :
      var.env == "prod" ? local.couchbase_prod_index_keys : [],
      key
    )
  }
}
