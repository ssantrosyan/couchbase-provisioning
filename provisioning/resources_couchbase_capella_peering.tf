resource "couchbase-capella_network_peer" "new_network_peer_prod" {
  count           = var.env == "prod" ? 1 : 0
  organization_id = local.couchbase_org_id[var.env]
  project_id      = couchbase-capella_project.project.0.id
  cluster_id      = couchbase-capella_cluster.cluster["company-cluster"].id
  name            = "tf-${var.env}-company-cluster-vpc-peering"
  provider_type   = "aws"
  provider_config = {
    aws_config = {
      account_id = data.aws_caller_identity.current.account_id
      vpc_id     = module.vpc.vpc_id
      cidr       = module.vpc.vpc_cidr_block
      region     = data.aws_region.current.name
    }
  }
  lifecycle {
    ignore_changes = [
      provider_config,
      provider_type,
      status
    ]
  }
  provisioner "local-exec" {
    command = "sleep 30 && ${join(" && ", self.commands)} && sleep 60"
  }
}
