locals {
  couchbase_capella_db_credentials = {
    service_name1_user = {
      access = [
        {
          privileges = ["data_writer", "data_reader"]
          resources = {
            buckets = [
              {
                name = "bucket1"
                scopes = [
                  {
                    name = "collection1"
                  }
                ]
              }
            ]
          }
        }
      ]
      cluster_name = local.couchbase_cluster_name
      secret_name  = "/${var.env}/service_name1/couchbase-capella"
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    },
    service_name2_user = {
      access = [
        {
          privileges = ["data_writer", "data_reader"]
          resources = {
            buckets = [
              {
                name = "bucket2"
                scopes = [
                  {
                    name = "collection2"
                  }
                ]
              }
            ]
          }
        }
      ]
      cluster_name = local.couchbase_cluster_name
      secret_name  = "/${var.env}/service_name2/couchbase-capella"
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
  }
  ###Staging Environment###
  couchbase_capella_db_stage_credentials = {
    service_name1_user_stage = {
      access = [
        {
          privileges = ["data_writer", "data_reader"]
          resources = {
            buckets = [
              {
                name = "bucket1_stage"
                scopes = [
                  {
                    name = "collection1"
                  }
                ]
              }
            ]
          }
        }
      ]
      cluster_name = local.couchbase_cluster_name
      secret_name  = "/${var.env}/service_name1/couchbase-capella"
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    },
    service_name2_user_stage = {
      access = [
        {
          privileges = ["data_writer", "data_reader"]
          resources = {
            buckets = [
              {
                name = "bucket2_stage"
                scopes = [
                  {
                    name = "collection2"
                  }
                ]
              }
            ]
          }
        }
      ]
      cluster_name = local.couchbase_cluster_name
      secret_name  = "/${var.env}/service_name2/couchbase-capella"
      cluster_id   = var.couchbase_default_cluster_id
      project_id   = var.couchbase_default_project_id
    }
  }

  couchbase_capella_all_db_credentials = merge(
    local.couchbase_capella_db_credentials,
    local.couchbase_capella_db_stage_credentials
  )

  couchbase_capella_dev_credential_keys   = keys(local.couchbase_capella_db_credentials)
  couchbase_capella_stage_credential_keys = keys(local.couchbase_capella_db_stage_credentials)
  couchbase_capella_prod_credential_keys  = keys(local.couchbase_capella_db_credentials)

  couchbase_capella_unified_db_credentials = {
    for key, config in local.couchbase_capella_all_db_credentials :
    key => config
    if contains(
      var.env == "dev" ? local.couchbase_capella_dev_credential_keys :
      var.env == "stage" ? local.couchbase_capella_stage_credential_keys :
      var.env == "prod" ? local.couchbase_capella_prod_credential_keys : [],
      key
    )
  }
}
