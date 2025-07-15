locals {
  couchbase_capella_scopes_config = {
    scope1 = {
      bucket_name  = "bucket1"
      cluster_name = local.couchbase_cluster_name
      scope_name   = "scope1"
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
    scope2 = {
      bucket_name  = "bucket2"
      cluster_name = local.couchbase_cluster_name
      scope_name   = "scope2"
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
  }

  couchbase_capella_stage_scopes_config = {
    scope1_stage = {
      bucket_name  = "bucket1_stage"
      cluster_name = local.couchbase_cluster_name
      scope_name   = "scope1"
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
    scope2_stage = {
      bucket_name  = "bucket2_stage"
      cluster_name = local.couchbase_cluster_name
      scope_name   = "signalwise"
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
  }

  couchbase_capella_all_scopes_config = merge(
    local.couchbase_capella_scopes_config,
    local.couchbase_capella_stage_scopes_config
  )

  couchbase_capella_dev_scope_keys   = ["scope1", "scope2"]
  couchbase_capella_stage_scope_keys = ["scope1_stage", "scope2_stage"]
  couchbase_capella_prod_scope_keys  = ["scope1", "scope2"]

  couchbase_capella_unified_scopes_config = {
    for key, config in local.couchbase_capella_all_scopes_config :
    key => config
    if contains(
      var.env == "dev" ? local.couchbase_capella_dev_scope_keys :
      var.env == "stage" ? local.couchbase_capella_stage_scope_keys :
      var.env == "prod" ? local.couchbase_capella_prod_scope_keys : [],
      key
    )
  }
}
