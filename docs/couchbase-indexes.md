# Couchbase Indexes Documentation

This document describes the Couchbase Capella indexes created and managed by this Terraform configuration.

## Overview

Couchbase indexes are critical for query performance, enabling efficient data retrieval through N1QL queries. This configuration manages various index types including primary indexes, secondary indexes, and collection-specific indexes.

## Resource Configuration

**Resource**: `couchbase-capella_query_index.index`  
**File**: `resources_couchbase_capella_indexes.tf`  
**Constants**: `constants_couchbase_indexes.tf`  
**Provider**: `couchbase-capella`

## Index Types

### Primary Indexes
- **Purpose**: Enable document retrieval by document key
- **Requirement**: Required for N1QL queries without specific secondary indexes
- **Performance**: Slower than secondary indexes for filtered queries
- **Coverage**: All documents in a collection

### Secondary Indexes
- **Purpose**: Optimize specific query patterns
- **Performance**: Fast retrieval for indexed fields
- **Selectivity**: Filter documents based on indexed fields
- **Maintenance**: Automatically maintained by Couchbase

### Composite Indexes
- **Purpose**: Optimize queries with multiple conditions
- **Fields**: Multiple fields in a single index
- **Performance**: Most efficient for multi-field queries
- **Order**: Field order matters for performance

## Index Configuration

### Index Structure

Indexes are defined in `constants_couchbase_indexes.tf`:

```hcl
couchbase_capella_index_config = {
  primary_index_bucket1 = {
    bucket_name     = "bucket1"
    scope_name      = "scope1"
    collection_name = "collection1"
    cluster_name    = local.couchbase_cluster_name
    cluster_id      = var.couchbase_default_cluster_id
    project_id      = var.couchbase_default_project_id
    index_name      = "#primary"
    index_keys      = []
    is_primary      = true
    where_clause    = ""
  }
  
  secondary_index_email = {
    bucket_name     = "bucket1"
    scope_name      = "scope1"
    collection_name = "collection1"
    cluster_name    = local.couchbase_cluster_name
    cluster_id      = var.couchbase_default_cluster_id
    project_id      = var.couchbase_default_project_id
    index_name      = "idx_user_email"
    index_keys      = ["email"]
    is_primary      = false
    where_clause    = "type = 'user'"
  }
}
```

### Index Properties

#### Core Configuration
- **Index Name**: Unique identifier for the index
- **Index Keys**: Fields to index (empty for primary)
- **Is Primary**: Boolean flag for primary index
- **Where Clause**: Optional filtering condition
- **Collection Scope**: Specific collection targeting

#### Advanced Properties
- **Partition**: Partitioned indexes for large datasets
- **Replica**: Index replicas for high availability
- **Defer Build**: Defer index building until later
- **Num Replica**: Number of index replicas

## Index Categories

### User Management Indexes
```hcl
user_indexes = {
  primary_users = {
    index_name = "#primary"
    is_primary = true
    collection_name = "users"
  }
  
  idx_user_email = {
    index_name = "idx_user_email"
    index_keys = ["email"]
    where_clause = "type = 'user' AND active = true"
  }
  
  idx_user_profile = {
    index_name = "idx_user_profile"
    index_keys = ["username", "created_date"]
  }
}
```

### Application Indexes
```hcl
application_indexes = {
  idx_session_token = {
    index_name = "idx_session_token"
    index_keys = ["session_token"]
    collection_name = "sessions"
    where_clause = "type = 'session'"
  }
  
  idx_order_status = {
    index_name = "idx_order_status"
    index_keys = ["status", "created_date"]
    collection_name = "orders"
  }
}
```

### Analytics Indexes
```hcl
analytics_indexes = {
  idx_event_timestamp = {
    index_name = "idx_event_timestamp"
    index_keys = ["timestamp", "event_type"]
    collection_name = "events"
  }
  
  idx_metrics_date = {
    index_name = "idx_metrics_date"
    index_keys = ["date", "metric_type", "value"]
    collection_name = "metrics"
  }
}
```

## Index Design Patterns

### Single Field Indexes
```sql
-- Simple index on single field
CREATE INDEX idx_user_id ON `bucket`.`scope`.`collection`(user_id)
WHERE type = 'user'
```

### Composite Indexes
```sql
-- Multi-field index for complex queries
CREATE INDEX idx_user_status_date ON `bucket`.`scope`.`collection`(status, created_date, user_id)
WHERE type = 'user'
```

### Functional Indexes
```sql
-- Index on expression
CREATE INDEX idx_user_email_lower ON `bucket`.`scope`.`collection`(LOWER(email))
WHERE type = 'user'
```

### Array Indexes
```sql
-- Index on array elements
CREATE INDEX idx_user_tags ON `bucket`.`scope`.`collection`(DISTINCT ARRAY tag FOR tag IN tags END)
WHERE type = 'user'
```

## Performance Optimization

### Index Selection Strategy

#### Query Analysis
1. **Identify Common Queries**: Analyze application query patterns
2. **Filter Selectivity**: Index fields with high selectivity
3. **Sort Operations**: Index fields used in ORDER BY
4. **Join Conditions**: Index fields used in JOIN operations

#### Index Design Guidelines
```hcl
# High-performance index design
optimized_indexes = {
  # Most selective field first
  idx_compound_optimal = {
    index_keys = ["status", "user_id", "created_date"]
    where_clause = "type = 'order' AND status IN ['pending', 'processing']"
  }
  
  # Include covering fields
  idx_covering = {
    index_keys = ["user_id", "status", "total_amount", "created_date"]
    where_clause = "type = 'order'"
  }
}
```

### Index Maintenance

#### Build Strategy
- **Deferred Build**: Build multiple indexes simultaneously
- **Online Building**: Non-blocking index creation
- **Progress Monitoring**: Track index build progress

#### Performance Monitoring
```bash
# Monitor index usage
couchbase-capella index stats --index-name <index-name>

# Check index status
couchbase-capella index list --collection <collection>

# Analyze query performance
couchbase-capella query explain --query "SELECT * FROM bucket WHERE field = 'value'"
```

## Resource Dependencies

### Collection Dependency
```hcl
# Indexes depend on collections
bucket_id = couchbase-capella_bucket.bucket[each.value.bucket_name].id
scope_name = each.value.scope_name
collection_name = each.value.collection_name
```

### Build Order
1. **Collections** → **Primary Indexes** → **Secondary Indexes**
2. **High Priority Indexes**: Build critical indexes first
3. **Batch Creation**: Group related indexes for efficiency

## Index Management Operations

### Terraform Operations

#### Create Indexes
```bash
# Plan index creation
terraform plan -target=couchbase-capella_query_index.index

# Create indexes
terraform apply -target=couchbase-capella_query_index.index
```

#### Update Indexes
```bash
# Recreate index with new definition
terraform taint couchbase-capella_query_index.index["index_name"]
terraform apply
```

#### Monitor Index Creation
```bash
# Check index build status
terraform show couchbase-capella_query_index.index

# List all indexes
terraform state list | grep index
```

### Manual Index Management

#### Using N1QL
```sql
-- Create index manually
CREATE INDEX idx_manual ON `bucket`.`scope`.`collection`(field1, field2)
WHERE condition

-- Drop index
DROP INDEX `bucket`.`scope`.`collection`.idx_manual

-- Build deferred indexes
BUILD INDEX ON `bucket`.`scope`.`collection`(idx1, idx2, idx3)
```

#### Using CLI
```bash
# Create index via CLI
cbq -e "CREATE INDEX idx_cli ON bucket.scope.collection(field)"

# Monitor index building
cbq -e "SELECT * FROM system:indexes WHERE name = 'idx_cli'"
```

## Performance Tuning

### Query Optimization

#### Index Coverage
```sql
-- Covering index eliminates document fetch
CREATE INDEX idx_covering ON `bucket`.`scope`.`collection`(user_id, status, amount, date)
WHERE type = 'transaction'

-- Query uses only indexed fields
SELECT user_id, status, amount FROM `bucket`.`scope`.`collection`
WHERE user_id = 'user123' AND type = 'transaction'
```

#### Index Intersection
```sql
-- Multiple indexes can be combined
CREATE INDEX idx_user ON `bucket`.`scope`.`collection`(user_id)
CREATE INDEX idx_date ON `bucket`.`scope`.`collection`(created_date)

-- Query can use both indexes
SELECT * FROM `bucket`.`scope`.`collection`
WHERE user_id = 'user123' AND created_date > '2024-01-01'
```

### Index Statistics

#### Usage Metrics
- **Scan Count**: Number of times index was scanned
- **Items Scanned**: Number of items examined
- **Items Returned**: Number of items returned
- **Scan Duration**: Time spent scanning index

#### Performance Indicators
```bash
# Index efficiency metrics
index_efficiency = items_returned / items_scanned

# High efficiency (>0.1) indicates good index selectivity
# Low efficiency (<0.01) suggests index optimization needed
```

## Environment-Specific Considerations

### Development Environment
- **Minimal Indexes**: Only essential indexes for functionality
- **Cost Optimization**: Fewer indexes to reduce memory usage
- **Build Time**: Faster deployment with fewer indexes

### Production Environment
- **Comprehensive Coverage**: All performance-critical indexes
- **High Availability**: Index replicas for fault tolerance
- **Monitoring**: Detailed index performance tracking

### Index Sizing
```hcl
# Environment-specific index configuration
index_config_by_env = {
  dev = {
    build_replicas = 0
    partition_count = 1
    defer_build = false
  }
  
  prod = {
    build_replicas = 1
    partition_count = 4
    defer_build = true
  }
}
```

## Troubleshooting

### Common Issues

#### Index Build Failures
```
Error: Index build failed due to insufficient memory
```
**Solution**: Increase cluster memory or build indexes sequentially

#### Query Performance Issues
```
Error: Query timeout due to missing index
```
**Solution**: Create appropriate indexes for query patterns

#### Index Space Issues
```
Error: Insufficient disk space for index
```
**Solution**: Increase storage or optimize index selection

### Debugging Steps

1. **Query Analysis**: Use EXPLAIN to understand query execution
2. **Index Usage**: Monitor index statistics and usage patterns
3. **Performance Profiling**: Identify slow queries and missing indexes
4. **Resource Monitoring**: Check memory and disk usage for indexes

### Debug Commands
```sql
-- Explain query execution plan
EXPLAIN SELECT * FROM `bucket`.`scope`.`collection` WHERE field = 'value'

-- Show index information
SELECT * FROM system:indexes WHERE keyspace_id = 'bucket'

-- Monitor index stats
SELECT * FROM system:index_stats WHERE index_name = 'idx_name'
```

## Best Practices

### Index Design
1. **Analyze Query Patterns**: Design indexes based on actual queries
2. **Field Order Matters**: Place most selective fields first
3. **Avoid Over-Indexing**: Too many indexes slow down writes
4. **Use Partial Indexes**: Add WHERE clauses to reduce index size

### Performance
1. **Monitor Regularly**: Track index usage and performance
2. **Update Statistics**: Ensure query optimizer has current data
3. **Batch Operations**: Group index operations for efficiency
4. **Test Performance**: Validate index effectiveness with real queries

### Maintenance
1. **Regular Review**: Periodically review and optimize indexes
2. **Remove Unused**: Drop indexes that are not being used
3. **Version Control**: Track index changes in version control
4. **Documentation**: Document index purpose and usage patterns

### Security
1. **Access Control**: Secure index management operations
2. **Audit Logging**: Track index creation and modification
3. **Resource Limits**: Monitor index resource consumption
4. **Backup Strategy**: Include indexes in backup procedures

## Advanced Features

### Partitioned Indexes
```sql
-- Partition large indexes for better performance
CREATE INDEX idx_partitioned ON `bucket`.`scope`.`collection`(user_id, date)
PARTITION BY HASH(user_id)
```

### Index Replicas
```sql
-- Create index replicas for high availability
CREATE INDEX idx_replica ON `bucket`.`scope`.`collection`(field)
WITH {"num_replica": 1}
```

### Deferred Build
```sql
-- Create multiple indexes and build together
CREATE INDEX idx1 ON `bucket`.`scope`.`collection`(field1) WITH {"defer_build": true}
CREATE INDEX idx2 ON `bucket`.`scope`.`collection`(field2) WITH {"defer_build": true}
BUILD INDEX ON `bucket`.`scope`.`collection`(idx1, idx2)
```

## Related Documentation

- [Couchbase Scopes and Collections](couchbase-scopes-collections.md) - Data organization for indexes
- [Database Credentials](database-credentials.md) - Access control for index operations
- [Couchbase Buckets](couchbase-buckets.md) - Storage layer for indexes
- [Couchbase Clusters](couchbase-clusters.md) - Infrastructure hosting indexes 