# Couchbase Clusters Documentation

This document describes the Couchbase Capella clusters created and managed by this Terraform configuration.

## Overview

Couchbase Capella clusters are the compute and storage infrastructure that host your databases. This configuration supports both automated cluster creation and integration with manually created clusters (such as free tier clusters).

## Resource Configuration

**Resource**: `couchbase-capella_cluster.cluster`  
**File**: `resources_couchbase_capella_clusters.tf`  
**Provider**: `couchbase-capella`

## Cluster Types

### Automated Clusters
Created automatically by Terraform for production environments.

### Manual Clusters
Pre-existing clusters (typically free tier) that are referenced by ID.

## Environment-Based Deployment

### Cluster Architecture

The infrastructure uses a shared cluster approach for cost efficiency:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Development   │    │     Staging     │    │   Production    │
│   Environment   │    │   Environment   │    │   Environment   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┘                       │
                    │                                     │
         ┌─────────────────┐                   ┌─────────────────┐
         │  Shared Dev     │                   │   Dedicated     │
         │    Cluster      │                   │ Prod Cluster    │
         │  (Manual/Free)  │                   │  (Automated)    │
         └─────────────────┘                   └─────────────────┘
```

### Cluster Environments

Defined in `constants.tf`:
```hcl
couchbase_cluster_env        = ["prod"]           # Automated clusters
couchbase_manual_cluster_env = ["dev"]            # Manual clusters (shared by dev/stage)
```

### Environment Configurations

#### Development Environment
- **Type**: Manual cluster (free tier)
- **Cluster ID**: Specified in `dev.tfvars`
- **Purpose**: Development and testing
- **Cost**: Free tier usage
- **Shared with**: Staging environment

#### Staging Environment
- **Type**: Shared manual cluster (uses dev cluster)
- **Cluster ID**: Same as development cluster
- **Purpose**: Pre-production testing on shared infrastructure
- **Cost**: Shared with development (cost-efficient)
- **Isolation**: Logical separation via scopes/collections

#### Production Environment
- **Type**: Dedicated automated cluster
- **Configuration**: Full specification in `couchbase_clusters_params`
- **Purpose**: Production workloads with dedicated resources
- **Cost**: Based on cluster specifications
- **Isolation**: Complete physical separation

## Cluster Configuration

### Automated Cluster Properties

#### Basic Configuration
- **Name Pattern**: `tf-{env}-{cluster-key}-{region}`
- **Description**: Configurable per cluster
- **Couchbase Server Version**: 7.6
- **Lifecycle Protection**: `prevent_destroy = true`

#### Infrastructure Configuration
```hcl
cloud_provider = {
  type   = "aws"           # Cloud provider
  region = "us-east-1"     # AWS region
  cidr   = "10.0.0.0/20"   # Network CIDR
}

service_groups = [
  {
    node = {
      compute = {
        cpu = 4
        ram = 16
      }
      disk = {
        storage = 50
        type    = "io2"
        iops    = 3000
      }
    }
    num_of_nodes = 3
    services     = ["data", "index", "query"]
  }
]
```

#### Availability Configuration
```hcl
availability = {
  type = "multi"    # single, multi
}

support = {
  plan     = "basic"     # basic, developer, enterprise
  timezone = "PT"        # Support timezone
}
```

### Manual Cluster Configuration

Manual clusters are referenced using:
- **Cluster ID**: From environment variables or constants
- **Project ID**: From environment variables or constants

#### Manual Cluster IDs

Defined in `constants.tf`:
```hcl
couchbase_manual_clusters_id = {
  dev   = "your Dev cluster ID"    # Company Org ID
  stage = "Your Dev Cluster ID"    # Company Org ID
}
```

## Cluster Parameters

### Parameter Structure

Clusters are configured through `var.couchbase_clusters_params`:

```hcl
variable "couchbase_clusters_params" {
  default = {
    "cluster-name" = {
      description       = "Production cluster"
      availability_type = "multi"
      support = {
        plan     = "enterprise"
        timezone = "PT"
      }
      cloud_provider = {
        type   = "aws"
        region = "us-west-2"
        cidr   = "10.0.0.0/20"
      }
      service_groups = [
        {
          node = {
            compute = {
              cpu = 8
              ram = 32
            }
            disk = {
              storage = 100
              type    = "io2"
              iops    = 5000
            }
          }
          num_of_nodes = 3
          services     = ["data", "index", "query"]
        }
      ]
    }
  }
}
```

## Dependencies

### Project Dependency
```hcl
project_id = lookup(each.value, "project_id", couchbase-capella_project.project.0.id)
depends_on = [couchbase-capella_project.project]
```

### Organization Reference
```hcl
organization_id = lookup(each.value, "org_id", local.couchbase_org_id[var.env])
```

## Environment-Specific Configuration

### Development & Staging (Shared Cluster)
```hcl
# dev.tfvars and stage.tfvars both reference the same cluster
couchbase_default_cluster_id = "your couchbase cluster id"  # Shared free tier cluster
couchbase_default_project_id = "your couchbase project id"  # Shared project

# Data separation achieved through:
# - Environment-specific scopes and collections
# - Logical isolation within the same cluster
# - Different bucket configurations per environment
```

### Production (Dedicated Cluster)
Configured through `couchbase_clusters_params` variable:
- Dedicated cluster infrastructure
- Multi-AZ deployment
- Enterprise support
- High-performance storage
- Multiple service groups
- Complete isolation from dev/stage

## Network Configuration

### AWS Integration
- **VPC CIDR**: Must not overlap with AWS VPC
- **Peering**: Configured separately in VPC peering resources
- **Security**: Network isolation and security groups

### CIDR Planning
- **Cluster CIDR**: Specified in cluster configuration
- **AWS VPC**: `10.0.0.0/16` (or environment-specific)
- **No Overlap**: Ensure CIDRs don't conflict

## Performance Configuration

### Compute Resources
- **CPU**: 4-32 cores per node
- **RAM**: 16-256 GB per node
- **Nodes**: 3+ for high availability

### Storage Configuration
- **Type**: `io2` for high performance
- **Size**: 50GB - multiple TB
- **IOPS**: 3000+ for production workloads

### Service Distribution
- **Data Service**: Data storage and retrieval
- **Index Service**: Query performance
- **Query Service**: N1QL query processing
- **Analytics Service**: Analytical workloads (optional)
- **Search Service**: Full-text search (optional)

## Monitoring and Management

### Cluster Metrics
- CPU utilization
- Memory usage
- Disk I/O
- Network throughput
- Query performance

### Health Checks
```bash
# Check cluster status
couchbase-capella cluster get --cluster-id <cluster-id>

# List all clusters
couchbase-capella cluster list --project-id <project-id>

# Monitor cluster health
couchbase-capella cluster metrics --cluster-id <cluster-id>
```

## Scaling Operations

### Vertical Scaling
- Increase node CPU/RAM
- Requires cluster restart
- Plan for maintenance window

### Horizontal Scaling
- Add/remove nodes
- Online operation
- Auto-rebalancing

### Storage Scaling
- Increase disk size
- Online operation
- Monitor performance impact

## Backup and Recovery

### Automated Backups
- Point-in-time recovery
- Cross-region replication
- Retention policies

### Manual Backups
```bash
# Create backup
couchbase-capella backup create --cluster-id <cluster-id>

# List backups
couchbase-capella backup list --cluster-id <cluster-id>

# Restore from backup
couchbase-capella backup restore --backup-id <backup-id>
```

## Cost Optimization

### Right-Sizing
- Monitor actual resource usage
- Adjust node specifications
- Optimize service distribution

### Reserved Capacity
- Long-term commitments
- Significant cost savings
- Planning required

### Development Optimization
- Use free tier for development
- Minimal resource allocation
- Automated shutdown for non-production

## Troubleshooting

### Common Issues

#### Cluster Creation Timeout
```
Error: Timeout waiting for cluster to be ready
```
**Solution**: Increase timeout, check quotas

#### CIDR Conflicts
```
Error: CIDR block overlaps with existing network
```
**Solution**: Choose non-overlapping CIDR blocks

#### Insufficient Quota
```
Error: Exceeded organization limits
```
**Solution**: Request quota increase or optimize usage

### Debugging Steps

1. **Check Quotas**: Verify organization and project limits
2. **Validate Configuration**: Review cluster parameters
3. **Monitor Progress**: Check cluster creation status
4. **Review Logs**: Examine Terraform and Capella logs

## Best Practices

### Configuration Management
- Use consistent naming conventions
- Version control all configurations
- Environment-specific parameters

### Security
- Network isolation
- Access control
- Certificate management
- Regular security updates

### Performance
- Appropriate node sizing
- Service distribution
- Storage optimization
- Regular performance tuning

### Cost Management
- Monitor usage patterns
- Right-size resources
- Use free tier for development
- Regular cost reviews

## Related Documentation

- [Couchbase Projects](couchbase-projects.md) - Project management
- [VPC Peering](vpc-peering.md) - Network connectivity
- [Database Credentials](database-credentials.md) - Access management
- [Couchbase Buckets](couchbase-buckets.md) - Data storage configuration 