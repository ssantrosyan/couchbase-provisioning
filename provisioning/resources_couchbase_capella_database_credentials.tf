resource "couchbase-capella_database_credential" "credentials" {
  depends_on      = [couchbase-capella_collection.collection]
  for_each        = local.couchbase_capella_unified_db_credentials
  access          = each.value.access
  name            = each.key
  organization_id = lookup(each.value, "organization_id", local.couchbase_org_id[var.env])
  cluster_id      = lookup(each.value, "cluster_id", "") != "" ? [for elem in data.couchbase-capella_clusters.clusters.0.data : elem if elem.id == each.value.cluster_id][0].id : couchbase-capella_cluster.cluster[each.value.cluster_name].id
  project_id      = lookup(each.value, "project_id", "") != "" ? [for elem in data.couchbase-capella_clusters.clusters.0.data : elem if elem.id == each.value.cluster_id][0].project_id : couchbase-capella_cluster.cluster[each.value.cluster_name].project_id
  password        = random_password.master[each.key].result
  lifecycle {
    prevent_destroy = true
  }
}

resource "random_password" "master" {
  for_each         = local.couchbase_capella_unified_db_credentials
  length           = 20
  special          = true
  override_special = "@,~,!,#,{,}"
  number           = true
  min_numeric      = 2
  lower            = true

  lifecycle {
    ignore_changes = [
      length,
      lower,
      min_numeric,
      override_special,
      number,
      special
    ]
  }
}

resource "aws_secretsmanager_secret" "couchbase_secrets" {
  for_each                = local.couchbase_capella_unified_db_credentials
  name                    = each.value.secret_name
  recovery_window_in_days = 0
  tags                    = merge({ Name = each.value.secret_name }, local.tags)
}

resource "aws_secretsmanager_secret_version" "couchbase_secrets_version" {
  for_each  = local.couchbase_capella_unified_db_credentials
  secret_id = aws_secretsmanager_secret.couchbase_secrets[each.key].id
  secret_string = jsonencode({
    COUCHBASE_USERNAME = couchbase-capella_database_credential.credentials[each.key].name
    COUCHBASE_PASSWORD = couchbase-capella_database_credential.credentials[each.key].password
    COUCHBASE_HOST     = format("couchbases://%s", lookup(each.value, "cluster_id", "") != "" ? [for elem in data.couchbase-capella_clusters.clusters.0.data : elem if elem.id == each.value.cluster_id][0].connection_string : couchbase-capella_cluster.cluster[each.value.cluster_name].connection_string)
  })
}
