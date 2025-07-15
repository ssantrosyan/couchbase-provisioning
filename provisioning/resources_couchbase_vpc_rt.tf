resource "aws_route" "couchbase_pub_route" {
  for_each                  = toset([for elem in module.vpc.public_route_table_ids: elem if var.env != "dev"])
  route_table_id            = each.value
  destination_cidr_block    = local.couchbase_vpc_cidr[var.env]
  vpc_peering_connection_id =replace(regex("pcx-.*", [for elem in couchbase-capella_network_peer.new_network_peer_prod.0.commands : elem][0]),"\"","")
}

resource "aws_route" "couchbase_private_route" {
  for_each                  = toset([for elem in module.vpc.private_route_table_ids: elem if var.env != "dev"])
  route_table_id            = each.value
  destination_cidr_block    = local.couchbase_vpc_cidr[var.env]
  vpc_peering_connection_id =replace(regex("pcx-.*", [for elem in couchbase-capella_network_peer.new_network_peer_prod.0.commands : elem][0]),"\"","")
}