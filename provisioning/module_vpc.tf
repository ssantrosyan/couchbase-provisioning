module "vpc" {
  source          = "terraform-aws-modules/vpc/aws"
  name            = "${var.env}-vpc"
  cidr            = "10.0.0.0/16"
  azs             = ["${var.region}a", "${var.region}b", "${var.region}c"]
  private_subnets = [
    "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"
  ]
  public_subnets = [
    "10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"
  ]
  private_subnet_names = [
    "${var.env}-vpc-private-${data.aws_region.current.name}a",
    "${var.env}-vpc-private-${data.aws_region.current.name}b",
    "${var.env}-vpc-private-${data.aws_region.current.name}c",
  ]
  public_subnet_names = [
    "${var.env}-vpc-public-${data.aws_region.current.name}a",
    "${var.env}-vpc-public-${data.aws_region.current.name}b",
    "${var.env}-vpc-public-${data.aws_region.current.name}c",
  ]
  enable_nat_gateway                                        = false
  enable_vpn_gateway                                        = false
  default_network_acl_name                                  = "${var.env}-acl"
  tags                                                      = local.tags
  map_public_ip_on_launch                                   = true
  public_subnet_enable_resource_name_dns_a_record_on_launch = true
  public_subnet_tags                                        = local.tags
  private_subnet_tags                                       = local.tags
}


resource "aws_eip" "nat_eip" {
  tags = merge({ Name = "${var.env}-private-nat-gw-eip" }, local.tags)
}
resource "aws_nat_gateway" "nat_gw" {
  tags          = merge({ Name = "${var.env}-private-nat-gw" }, local.tags)
  subnet_id     = module.vpc.public_subnets[0]
  allocation_id = aws_eip.nat_eip.id
}

resource "aws_route" "private_subnets_nat_access" {
  count                  = length(local.subnets_ids)
  route_table_id         = local.subnets_ids[count.index]
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
  destination_cidr_block = "0.0.0.0/0"

  depends_on             = [module.vpc]
}