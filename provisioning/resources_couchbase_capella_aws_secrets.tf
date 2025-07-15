resource "aws_secretsmanager_secret" "couchbase_common_secret" {
  name                    = local.couchbase_general_secret_name
  recovery_window_in_days = 0
  tags                    = merge({ Name : local.couchbase_general_secret_name }, local.tags)

}

resource "aws_secretsmanager_secret_version" "couchbase_common_secret_version" {
  secret_id = aws_secretsmanager_secret.couchbase_common_secret.id
  secret_string = jsonencode(merge(
    {
      couchbases_hostname         = format("couchbases://%s", contains(local.couchbase_cluster_env, var.env) ? couchbase-capella_cluster.cluster[local.couchbase_cluster_name].connection_string : [for elem in data.couchbase-capella_clusters.clusters.0.data : elem if elem.id == var.couchbase_default_cluster_id][0].connection_string)
      service_name1_user          = var.env == "stage" ? couchbase-capella_database_credential.credentials["service_name1_user_stage"].name : couchbase-capella_database_credential.credentials["service_name1_user"].name
      service_name1_user_password = var.env == "stage" ? couchbase-capella_database_credential.credentials["service_name1_user_stage"].password : couchbase-capella_database_credential.credentials["service_name1_user"].password
      service_name2_user          = var.env == "stage" ? couchbase-capella_database_credential.credentials["service_name2_user_stage"].name : couchbase-capella_database_credential.credentials["service_name2_user"].name
      service_name2_user_password = var.env == "stage" ? couchbase-capella_database_credential.credentials["service_name2_user_stage"].password : couchbase-capella_database_credential.credentials["service_name2_user"].password
    }
  ))
}