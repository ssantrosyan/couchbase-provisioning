# AWS Infrastructure Documentation

This document describes the AWS infrastructure components created by this Terraform project.

## Overview

The AWS infrastructure provides the networking foundation for Couchbase Capella connectivity and includes VPC, subnets, NAT gateways, and routing configurations.

## Resources Created

### VPC (Virtual Private Cloud)

**Resource**: `module.vpc`  
**File**: `module_vpc.tf`

#### Configuration
- **CIDR Block**: `10.0.0.0/16`
- **Name**: `{env}-vpc`
- **DNS Hostnames**: Enabled
- **DNS Resolution**: Enabled

#### Availability Zones
The VPC spans across three availability zones in the selected region:
- `{region}a`
- `{region}b` 
- `{region}c`

### Subnets

#### Private Subnets
- **Count**: 3 (one per AZ)
- **CIDR Blocks**: 
  - `10.0.1.0/24` - AZ a
  - `10.0.2.0/24` - AZ b
  - `10.0.3.0/24` - AZ c
- **Names**: `{env}-vpc-private-{region}{az}`
- **Purpose**: Internal resources, database connectivity

#### Public Subnets
- **Count**: 3 (one per AZ)
- **CIDR Blocks**: 
  - `10.0.101.0/24` - AZ a
  - `10.0.102.0/24` - AZ b
  - `10.0.103.0/24` - AZ c
- **Names**: `{env}-vpc-public-{region}{az}`
- **Purpose**: NAT gateway, public-facing resources
- **Auto-assign Public IP**: Enabled
- **DNS A Records**: Enabled

### NAT Gateway

**Resource**: `aws_nat_gateway.nat_gw`  
**File**: `module_vpc.tf`

#### Configuration
- **Name**: `{env}-private-nat-gw`
- **Location**: First public subnet (`10.0.101.0/24`)
- **Elastic IP**: Dedicated EIP attached
- **Purpose**: Outbound internet access for private subnets

### Elastic IP

**Resource**: `aws_eip.nat_eip`  
**File**: `module_vpc.tf`

#### Configuration
- **Name**: `{env}-private-nat-gw-eip`
- **Domain**: VPC
- **Purpose**: Static IP for NAT gateway

### Route Tables

#### Private Subnet Routing
**Resource**: `aws_route.private_subnets_nat_access`  
**File**: `module_vpc.tf`

- **Count**: 3 (one per private subnet)
- **Default Route**: `0.0.0.0/0` → NAT Gateway
- **Purpose**: Route private subnet traffic through NAT gateway

#### Public Subnet Routing
- **Default Route**: `0.0.0.0/0` → Internet Gateway
- **Managed by**: VPC module

### Network ACLs

**Resource**: Default Network ACL  
**Name**: `{env}-acl`

- **Default Rules**: Allow all inbound/outbound traffic
- **Customization**: Can be modified for additional security

## Environment-Specific Configurations

### Development
- **VPC CIDR**: `10.0.0.0/16`
- **NAT Gateway**: Single NAT gateway for cost optimization
- **High Availability**: Basic setup
- **Couchbase Connectivity**: Connects to shared dev cluster

### Staging
- **VPC CIDR**: `10.0.0.0/16`
- **NAT Gateway**: Single NAT gateway
- **High Availability**: Standard setup
- **Couchbase Connectivity**: Connects to same shared dev cluster as development

### Production
- **VPC CIDR**: `10.4.2.0/24` (overridden in constants)
- **NAT Gateway**: Single NAT gateway (can be scaled to multiple)
- **High Availability**: Multi-AZ deployment
- **Couchbase Connectivity**: Connects to dedicated production cluster

## Security Considerations

### Network Isolation
- **Private Subnets**: No direct internet access
- **Public Subnets**: Controlled internet access
- **NAT Gateway**: Secure outbound connectivity

### Traffic Flow
1. **Inbound**: Internet Gateway → Public Subnets
2. **Outbound from Private**: Private Subnets → NAT Gateway → Internet Gateway
3. **Internal**: VPC routing for inter-subnet communication

## Cost Optimization

### NAT Gateway Costs
- **Hourly Rate**: Charged per NAT gateway hour
- **Data Processing**: Charged per GB processed
- **Optimization**: Single NAT gateway across AZs (trade-off for HA)

### Alternative Options
- **NAT Instances**: Lower cost but requires management
- **VPC Endpoints**: For AWS service connectivity
- **Transit Gateway**: For complex multi-VPC scenarios

## Monitoring and Troubleshooting

### VPC Flow Logs
```bash
# Enable VPC Flow Logs (optional)
aws ec2 create-flow-logs \
  --vpc-id <vpc-id> \
  --resource-type VPC \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name VPCFlowLogs
```

### Connectivity Testing
```bash
# Test connectivity from private subnet
# (requires EC2 instance in private subnet)
curl -I http://www.google.com

# Check route tables
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=<vpc-id>"

# Verify NAT gateway status
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=<vpc-id>"
```

## Dependencies

### External Dependencies
- **AWS Provider**: Terraform AWS provider
- **VPC Module**: `terraform-aws-modules/vpc/aws`

### Internal Dependencies
- **Variables**: `var.env`, `var.region`
- **Local Values**: `local.tags`, `local.subnets_ids`

## Tags Applied

All resources are tagged with:
- **Terraform**: "true"
- **Environment**: `{env}`
- **SourceRepo**: "https://github.com/ssantrosyan/couchbase-provisioning.git"

## Terraform Commands

```bash
# Plan VPC changes
terraform plan -target=module.vpc

# Apply VPC changes only
terraform apply -target=module.vpc

# Destroy VPC (⚠️ WARNING: Will destroy all dependent resources)
terraform destroy -target=module.vpc
```

## Best Practices

1. **CIDR Planning**: Ensure CIDR blocks don't overlap with existing networks
2. **Multi-AZ**: Always deploy across multiple AZs for high availability
3. **Cost Monitoring**: Monitor NAT gateway usage and costs
4. **Security Groups**: Use security groups for instance-level security
5. **Backup Strategy**: Ensure VPC configuration is versioned and backed up

## Related Documentation

- [VPC Peering](vpc-peering.md) - Couchbase Capella connectivity
- [Couchbase Clusters](couchbase-clusters.md) - Database cluster deployment
- [AWS Secrets Manager](aws-secrets.md) - Secrets management integration 