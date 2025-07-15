# Couchbase Buckets Documentation

This document describes the Couchbase Capella buckets created and managed by this Terraform configuration.

## Overview

Couchbase buckets are containers for data storage that provide isolation, configuration, and resource allocation for your data. This configuration manages multiple bucket types with environment-specific settings.

## Resource Configuration

**Resource**: `couchbase-capella_bucket.bucket`  
**File**: `resources_couchbase_capella_buckets.tf`  
**Constants**: `constants_couchbase_buckets.tf`  
**Provider**: `couchbase-capella`

## Bucket Configuration

### Default Buckets

The configuration defines multiple bucket types in `couchbase_capella_bucket_config`:

#### Bucket1 (Couchbase Type)
```hcl
bucket1 = {
  memory_allocation_in_mb = 300
  type                    = "couchbase"
  cluster_name            = local.couchbase_cluster_name
  storage_backend         = "couchstore"
  cluster_id              = var.couchbase_default_cluster_id
  project_id              = var.couchbase_default_project_id
  replicas = {
    dev   : 0
    stage : 0
    prod  : 1
  }
}
```

#### Bucket2 (Ephemeral Type)
```hcl
bucket2 = {
  memory_allocation_in_mb = 300
  cluster_name            = local.couchbase_cluster_name
  type                    = "ephemeral"
  cluster_id              = var.couchbase_default_cluster_id
  project_id              = var.couchbase_default_project_id
  replicas = {
    dev   : 0
    stage : 0
    prod  : 1
  }
}
```

## Bucket Types

### Couchbase Buckets
- **Type**: `couchbase`
- **Storage**: Persistent disk storage
- **Use Case**: Standard data storage with persistence
- **Backend**: Couchstore or Magma
- **Features**: Full CRUD operations, indexing, replication

### Ephemeral Buckets
- **Type**: `ephemeral`
- **Storage**: Memory-only storage
- **Use Case**: Cache, session storage, temporary data
- **Persistence**: None (data lost on restart)
- **Performance**: Higher performance, lower latency

## Storage Backends

### Couchstore
- **Type**: Traditional B+ tree storage
- **Use Case**: General-purpose workloads
- **Performance**: Balanced read/write performance
- **Memory**: Moderate memory usage

### Magma
- **Type**: LSM-tree based storage engine
- **Use Case**: Write-heavy workloads, large datasets
- **Performance**: Optimized for large-scale data
- **Memory**: Lower memory footprint

## Environment-Specific Configuration

### Replica Settings

Replicas are configured per environment for high availability:

#### Development
- **Replicas**: 0 (no replication)
- **Purpose**: Cost optimization for development
- **Risk**: Single point of failure acceptable

#### Staging
- **Replicas**: 0 (no replication)
- **Purpose**: Cost-controlled testing environment
- **Risk**: Acceptable for testing

#### Production
- **Replicas**: 1 (single replica)
- **Purpose**: High availability and data protection
- **Risk**: Protection against node failures

### Memory Allocation

#### Standard Allocation
- **Default**: 300 MB per bucket
- **Adjustable**: Based on workload requirements
- **Monitoring**: Track memory usage and adjust

#### Scaling Considerations
```hcl
# Example scaling configuration
bucket_production = {
  memory_allocation_in_mb = 1024  # 1GB for production
  type                    = "couchbase"
  storage_backend         = "magma"
  replicas = {
    prod  : 2  # Multiple replicas for production
  }
}
```

## Bucket Properties

### Core Configuration
- **Name**: Derived from configuration key
- **Memory Allocation**: Configurable in MB
- **Type**: Couchbase or Ephemeral
- **Storage Backend**: Couchstore or Magma
- **Replicas**: Environment-specific replica count

### Advanced Settings
- **Compression**: Configurable compression settings
- **TTL**: Time-to-live for documents
- **Conflict Resolution**: Sequence-based or timestamp-based
- **Max TTL**: Maximum time-to-live value

## Resource Dependencies

### Cluster Dependency
```hcl
cluster_id = lookup(each.value, "cluster_id", var.couchbase_default_cluster_id)
```

### Project Dependency
```hcl
project_id = lookup(each.value, "project_id", var.couchbase_default_project_id)
```

### Organization Reference
```hcl
organization_id = local.couchbase_org_id[var.env]
```

## Bucket Management Operations

### Creation Process
1. **Validation**: Check cluster capacity and quotas
2. **Memory Allocation**: Reserve specified memory
3. **Replication Setup**: Configure replica count
4. **Index Creation**: Set up primary indexes
5. **Access Control**: Configure bucket-level permissions

### Terraform Operations

#### Create Buckets
```bash
# Plan bucket creation
terraform plan -target=couchbase-capella_bucket.bucket

# Create buckets
terraform apply -target=couchbase-capella_bucket.bucket
```

#### Update Buckets
```bash
# Update memory allocation
terraform apply -var='bucket_memory_mb=512'

# Update replica count
terraform apply -var='replica_count=2'
```

#### View Bucket Information
```bash
# Show bucket state
terraform show couchbase-capella_bucket.bucket

# List all buckets
terraform state list | grep bucket
```

## Performance Considerations

### Memory Sizing
- **Base Requirement**: Minimum 100MB per bucket
- **Data Size**: 10-20% of total data size
- **Indexes**: Additional memory for indexes
- **Working Set**: Active data in memory

### Replica Impact
- **Storage**: Each replica doubles storage requirements
- **Network**: Replication traffic between nodes
- **Consistency**: Eventual consistency with replicas
- **Performance**: Slight impact on write performance

### Storage Backend Selection

#### Choose Couchstore When:
- General-purpose workloads
- Balanced read/write patterns
- Traditional RDBMS-like access patterns
- Moderate data sizes

#### Choose Magma When:
- Write-heavy workloads
- Large datasets (>1TB)
- Analytics workloads
- Cost optimization for storage

## Monitoring and Metrics

### Key Metrics
- **Memory Usage**: Track bucket memory consumption
- **Disk Usage**: Monitor storage utilization
- **Operation Rate**: Monitor read/write operations
- **Cache Hit Ratio**: Track data access patterns
- **Replication Lag**: Monitor replica synchronization

### Health Checks
```bash
# Check bucket status
couchbase-capella bucket get --bucket-name <bucket-name>

# List all buckets
couchbase-capella bucket list --cluster-id <cluster-id>

# Bucket statistics
couchbase-capella bucket stats --bucket-name <bucket-name>
```

## Scaling and Optimization

### Vertical Scaling
- **Memory Increase**: Add more RAM allocation
- **Storage Upgrade**: Switch storage backends
- **Index Optimization**: Add or optimize indexes

### Horizontal Scaling
- **Add Replicas**: Increase replica count
- **Cluster Expansion**: Add nodes to cluster
- **Bucket Distribution**: Create additional buckets

### Performance Tuning
```hcl
# Optimized production bucket
bucket_optimized = {
  memory_allocation_in_mb = 2048
  type                    = "couchbase"
  storage_backend         = "magma"
  compression_mode        = "active"
  max_ttl                 = 0
  replicas = {
    prod : 2
  }
}
```

## Data Management

### Document Operations
- **CRUD**: Create, Read, Update, Delete operations
- **Batch Operations**: Bulk data operations
- **Transactions**: ACID transaction support
- **Expiry**: Document TTL management

### Backup and Recovery
- **Automated Backups**: Cluster-level backup policies
- **Point-in-Time Recovery**: Restore to specific timestamps
- **Cross-Region Backup**: Backup to different regions
- **Manual Backup**: On-demand backup operations

## Security Considerations

### Access Control
- **Bucket-Level Permissions**: Read, write, admin access
- **User Management**: Bucket-specific users
- **Application Authentication**: Service account access
- **Network Security**: VPC and security group rules

### Encryption
- **At Rest**: Automatic encryption of stored data
- **In Transit**: TLS encryption for client connections
- **Key Management**: Integration with key management systems

## Troubleshooting

### Common Issues

#### Insufficient Memory
```
Error: Not enough memory available for bucket
```
**Solution**: Increase cluster memory or reduce bucket allocation

#### Replica Creation Failed
```
Error: Unable to create replica
```
**Solution**: Check node availability and cluster health

#### Storage Backend Conflict
```
Error: Storage backend not supported
```
**Solution**: Verify cluster version and backend compatibility

### Debugging Steps

1. **Check Cluster Health**: Verify cluster is operational
2. **Validate Memory**: Ensure sufficient memory available
3. **Review Quotas**: Check bucket and cluster limits
4. **Monitor Creation**: Track bucket creation progress

## Best Practices

### Configuration
- Start with conservative memory allocation
- Plan replica strategy based on availability requirements
- Choose appropriate storage backend for workload
- Use consistent naming conventions

### Performance
- Monitor memory usage regularly
- Optimize bucket count vs. size trade-offs
- Plan for growth in data and access patterns
- Regular performance testing

### Security
- Implement least privilege access
- Regular access review and cleanup
- Monitor bucket access patterns
- Enable audit logging

### Cost Management
- Monitor memory and storage usage
- Optimize replica count for requirements
- Regular cleanup of unused buckets
- Track costs per bucket

## Related Documentation

- [Couchbase Scopes and Collections](couchbase-scopes-collections.md) - Data organization within buckets
- [Couchbase Indexes](couchbase-indexes.md) - Query performance optimization
- [Database Credentials](database-credentials.md) - Access management for buckets
- [Couchbase Clusters](couchbase-clusters.md) - Cluster infrastructure for buckets 