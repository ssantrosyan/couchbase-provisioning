locals {
  couchbase_capella_collection_config = {
    name = "couchbase_capella_collection_config"
    collection1 = {
      name         = "collection1"
      bucket_name  = "bucket1"
      cluster_name = local.couchbase_cluster_name
      scope_name   = local.couchbase_capella_scopes_config.themes.scope_name
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
    collection2 = {
      name         = "collection2"
      bucket_name  = "bucket2"
      cluster_name = local.couchbase_cluster_name
      scope_name   = local.couchbase_capella_scopes_config.themes.scope_name
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
  }
  
  couchbase_capella_collection_stage_config = {
    collection1_stage = {
      name         = "collection1"
      bucket_name  = "bucket1_stage"
      cluster_name = local.couchbase_cluster_name
      scope_name   = local.couchbase_capella_stage_scopes_config.signalwise_stage.scope_name
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
    collection2_stage = {
      name         = "collection2"
      bucket_name  = "bucket2_stage"
      cluster_name = local.couchbase_cluster_name
      scope_name   = local.couchbase_capella_stage_scopes_config.signalwise_stage.scope_name
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
  }

  couchbase_capella_all_collection_config = merge(
    local.couchbase_capella_collection_config,
    local.couchbase_capella_collection_stage_config
  )

  couchbase_capella_dev_collection_keys = [
    "collection1",
    "collection2"
  ]
  couchbase_capella_stage_collection_keys = [
    "collection1_stage",
    "collection2_stage"
  ]
  couchbase_capella_prod_collection_keys = [
    "collection1",
    "collection2"
  ]

  couchbase_capella_unified_collection_config = {
    for key, config in local.couchbase_capella_all_collection_config :
    key => config
    if contains(
      var.env == "dev" ? local.couchbase_capella_dev_collection_keys :
      var.env == "stage" ? local.couchbase_capella_stage_collection_keys :
      var.env == "prod" ? local.couchbase_capella_prod_collection_keys : [],
      key
    )
  }
}
