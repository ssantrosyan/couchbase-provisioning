locals {
  couchbase_general_secret_name               = "${var.env}-couchbase-common-secrets"

  couchbase_org_id = {
    dev   = "Your Organization ID in Couchbase" # Company Org ID
    stage = "Your Organization ID in Couchbase" # Company Org ID
    prod  = "Your Organization ID in Couchbase" # Company Org ID
  }

  couchbase_manual_clusters_id = {
    dev   = "your Dev cluster ID" # Company Org ID
    stage = "Yout Dev Cluster ID" # Company Org ID
  }

  couchbase_manual_projects_id = {
    dev   = "Your Dev Project ID" # Company Org ID
    stage = ""                    # Company Org ID
    prod  = ""                    # Company Org ID
  }

  couchbase_project_env        = ["dev", "prod", "stage"]
  couchbase_cluster_env        = ["prod"]
  couchbase_manual_cluster_env = ["dev"]
  couchbase_vpc_cidr = {
    "prod" = "10.4.2.0/24"
  }

  subnets_ids = module.vpc.private_route_table_ids

  env_naming_dict = {
    dev   = "Company-Development"
    stage = "Company-Staging"
    prod  = "Company-Production"
  }

  tags = {
    Terraform   = "true"
    Environment = "${var.env}"
    SourceRepo  = "https://github.com/ssantrosyan/couchbase-provisioning.git"
  }

}