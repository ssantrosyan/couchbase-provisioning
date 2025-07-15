locals {
  couchbase_cluster_name = "company-cluster"

  couchbase_capella_bucket_config = {
    bucket1 = {
      memory_allocation_in_mb = 300
      type                    = "couchbase"
      cluster_name            = local.couchbase_cluster_name
      storage_backend         = "couchstore"
      cluster_id              = var.couchbase_default_cluster_id
      project_id              = var.couchbase_default_project_id
      replicas = {
        dev : 0
        stage : 0
        prod : 1
      }
    }
    bucket2 = {
      memory_allocation_in_mb = 300
      cluster_name            = local.couchbase_cluster_name
      type                    = "ephemeral"
      cluster_id              = var.couchbase_default_cluster_id
      project_id              = var.couchbase_default_project_id
      replicas = {
        dev : 0
        stage : 0
        prod : 1
      }
    }
  }
  couchbase_capella_stage_bucket_config = {
    bucket1_stage = {
      memory_allocation_in_mb = 300
      type                    = "couchbase"
      cluster_name            = local.couchbase_cluster_name
      storage_backend         = "couchstore"
      cluster_id              = var.couchbase_default_cluster_id
      project_id              = var.couchbase_default_project_id
      replicas = {
        dev : 0
        stage : 0
        prod : 0
      }
    }
    bucket2_stage = {
      memory_allocation_in_mb = 300
      cluster_name            = local.couchbase_cluster_name
      type                    = "ephemeral"
      cluster_id              = var.couchbase_default_cluster_id
      project_id              = var.couchbase_default_project_id
      replicas = {
        dev : 0
        stage : 0
        prod : 0
      }
    }
  }

  couchbase_capella_all_bucket_config = merge(
    local.couchbase_capella_bucket_config,
    local.couchbase_capella_stage_bucket_config
  )

  couchbase_capella_dev_bucket_keys   = ["bucket1", "bucket2"]
  couchbase_capella_stage_bucket_keys = ["bucket1_stage", "bucket2_stage"]
  couchbase_capella_prod_bucket_keys  = ["bucket1", "bucket2"]

  couchbase_capella_filtered_bucket_config = {
    for key, config in local.couchbase_capella_all_bucket_config :
    key => config
    if contains(
      var.env == "dev" ? local.couchbase_capella_dev_bucket_keys :
      var.env == "stage" ? local.couchbase_capella_stage_bucket_keys :
      var.env == "prod" ? local.couchbase_capella_prod_bucket_keys : [],
      key
    )
  }

  couchbase_capella_unified_bucket_config = {
    for key, config in local.couchbase_capella_all_bucket_config :
    key => config
    if contains(
      var.env == "dev" ? local.couchbase_capella_dev_bucket_keys :
      var.env == "stage" ? local.couchbase_capella_stage_bucket_keys :
      var.env == "prod" ? local.couchbase_capella_prod_bucket_keys : [],
      key
    )
  }
}
