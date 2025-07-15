# Couchbase Scopes and Collections Documentation

This document describes the Couchbase Capella scopes and collections created and managed by this Terraform configuration.

## Overview

Scopes and collections provide hierarchical data organization within Couchbase buckets. This modern approach replaces the traditional flat bucket structure with a more granular and organized data model similar to databases and tables in RDBMS.

## Data Hierarchy

```
Cluster
├── Project
    ├── Bucket
        ├── Scope (Database-like)
            ├── Collection (Table-like)
                └── Documents (Rows-like)
```

## Resource Configuration

### Scopes
**Resource**: `couchbase-capella_scope.scope`  
**File**: `resources_couchbase_capella_scopes.tf`  
**Constants**: `constants_couchbase_scopes.tf`

### Collections
**Resource**: `couchbase-capella_collection.collection`  
**File**: `resources_couchbase_capella_collections.tf`  
**Constants**: `constants_couchbase_collections.tf`

## Scope Configuration

### Scope Structure

Scopes are defined in `constants_couchbase_scopes.tf`:

```hcl
couchbase_capella_scope_config = {
  scope1 = {
    bucket_name  = "bucket1"
    cluster_name = local.couchbase_cluster_name
    cluster_id   = var.couchbase_default_cluster_id
    project_id   = var.couchbase_default_project_id
  }
  scope2 = {
    bucket_name  = "bucket2" 
    cluster_name = local.couchbase_cluster_name
    cluster_id   = var.couchbase_default_cluster_id
    project_id   = var.couchbase_default_project_id
  }
}
```

### Default Scopes

Every bucket automatically includes:
- **_default**: System default scope
- **_system**: System scope for internal use

### Custom Scopes

Custom scopes provide logical separation for:
- Different applications
- Data domains
- Security boundaries
- Development teams

## Collection Configuration

### Collection Structure

Collections are defined in `constants_couchbase_collections.tf`:

```hcl
couchbase_capella_collection_config = {
  collection1 = {
    bucket_name  = "bucket1"
    scope_name   = "scope1"
    cluster_name = local.couchbase_cluster_name
    cluster_id   = var.couchbase_default_cluster_id
    project_id   = var.couchbase_default_project_id
    max_ttl      = 0  # No expiry
  }
  collection2 = {
    bucket_name  = "bucket2"
    scope_name   = "scope2" 
    cluster_name = local.couchbase_cluster_name
    cluster_id   = var.couchbase_default_cluster_id
    project_id   = var.couchbase_default_project_id
    max_ttl      = 3600  # 1 hour expiry
  }
}
```

### TTL Configuration

Time-To-Live (TTL) settings control document expiration:

#### TTL Values
- **0**: No expiration (documents persist indefinitely)
- **> 0**: Expiration in seconds
- **Max Value**: 2,147,483,647 seconds (~68 years)

#### TTL Use Cases
- **Session Data**: Short TTL (1-24 hours)
- **Cache Data**: Medium TTL (minutes to hours)
- **Temporary Data**: Custom TTL based on requirements
- **Persistent Data**: TTL = 0 (no expiration)

## Resource Dependencies

### Scope Dependencies
```hcl
# Scopes depend on buckets
bucket_id = couchbase-capella_bucket.bucket[each.value.bucket_name].id
```

### Collection Dependencies
```hcl
# Collections depend on both buckets and scopes
bucket_id = couchbase-capella_bucket.bucket[each.value.bucket_name].id
scope_name = each.value.scope_name
```

### Dependency Chain
1. **Cluster** → **Project** → **Bucket** → **Scope** → **Collection**

## Configuration Examples

### Multi-Application Setup

```hcl
# Application-specific scopes
application_scopes = {
  user_service = {
    bucket_name = "app_data"
    # User service scope
  }
  order_service = {
    bucket_name = "app_data" 
    # Order service scope
  }
  analytics = {
    bucket_name = "analytics_data"
    # Analytics scope
  }
}

# Service-specific collections
user_collections = {
  users = {
    bucket_name = "app_data"
    scope_name  = "user_service"
    max_ttl     = 0  # Persistent users
  }
  sessions = {
    bucket_name = "app_data"
    scope_name  = "user_service" 
    max_ttl     = 86400  # 24 hour sessions
  }
}
```

### Environment-Specific TTL

```hcl
# TTL configuration by environment
collection_ttl_configuration = {
  dev = {
    cache_ttl    = 300     # 5 minutes
    session_ttl  = 3600    # 1 hour
    temp_ttl     = 1800    # 30 minutes
  }
  stage = {
    cache_ttl    = 600     # 10 minutes (shared cluster with dev)
    session_ttl  = 7200    # 2 hours
    temp_ttl     = 3600    # 1 hour
  }
  prod = {
    cache_ttl    = 1800    # 30 minutes (dedicated cluster)
    session_ttl  = 14400   # 4 hours
    temp_ttl     = 7200    # 2 hours
  }
}
```

### Data Isolation Strategy

#### Shared Cluster (Dev/Stage)
On the shared dev cluster, data separation is achieved through:

```hcl
# Environment-specific naming patterns
dev_collections = {
  "dev_users"     = { scope = "dev_user_service" }
  "dev_sessions"  = { scope = "dev_user_service" }
  "dev_orders"    = { scope = "dev_order_service" }
}

stage_collections = {
  "stage_users"   = { scope = "stage_user_service" }
  "stage_sessions"= { scope = "stage_user_service" }
  "stage_orders"  = { scope = "stage_order_service" }
}
```

#### Dedicated Cluster (Production)
Production uses a completely separate cluster with its own naming:

```hcl
prod_collections = {
  "users"     = { scope = "user_service" }
  "sessions"  = { scope = "user_service" }
  "orders"    = { scope = "order_service" }
}
```

## Access Patterns

### Query Patterns

#### Scope-Level Queries
```sql
-- Query across all collections in a scope
SELECT * FROM `bucket`.`scope`.`collection1` 
UNION ALL 
SELECT * FROM `bucket`.`scope`.`collection2`
```

#### Collection-Specific Queries
```sql
-- Query specific collection
SELECT * FROM `bucket`.`scope`.`collection` 
WHERE type = 'user'
```

#### Cross-Scope Queries
```sql
-- Query across scopes (requires appropriate indexes)
SELECT * FROM `bucket`.`scope1`.`collection1` u
JOIN `bucket`.`scope2`.`collection2` o ON u.id = o.user_id
```

### Document Access

#### Key-Value Operations
```javascript
// Collection-specific document access
await cluster.bucket('bucket').scope('scope').collection('collection').get('doc-id')
await cluster.bucket('bucket').scope('scope').collection('collection').upsert('doc-id', doc)
```

#### Batch Operations
```javascript
// Bulk operations within collection
const docs = await cluster.bucket('bucket').scope('scope').collection('collection').getMulti(['id1', 'id2', 'id3'])
```

## Indexing Strategy

### Collection-Specific Indexes
- Indexes are created at the collection level
- Better performance for collection-specific queries
- Reduced index maintenance overhead

### Index Planning
```sql
-- Collection-specific index
CREATE INDEX idx_user_email ON `bucket`.`scope`.`users`(email) WHERE type = 'user'

-- Cross-collection index (if needed)
CREATE INDEX idx_global_timestamp ON `bucket`.`scope`.`collection`(timestamp)
```

## Security and Access Control

### Collection-Level Permissions

Database credentials can be scoped to specific collections:

```hcl
service_access = {
  privileges = ["data_reader", "data_writer"]
  resources = {
    buckets = [
      {
        name = "bucket1"
        scopes = [
          {
            name = "scope1"
            collections = [
              {
                name = "collection1"
              }
            ]
          }
        ]
      }
    ]
  }
}
```

### Access Patterns
- **Application Isolation**: Each app accesses only its collections
- **Service Boundaries**: Microservices with collection-specific access
- **Data Governance**: Fine-grained data access control

## Performance Considerations

### Memory Management
- Collections share bucket memory allocation
- No per-collection memory limits
- Memory usage scales with document count and size

### Query Performance
- Collection-specific indexes improve performance
- Cross-collection queries may be slower
- Plan index strategy for access patterns

### Storage Efficiency
- Collections share bucket storage
- Document-level storage optimization
- TTL automatically cleans expired documents

## Monitoring and Management

### Collection Metrics
```bash
# Collection statistics
couchbase-capella collection stats --collection-name <collection>

# Document count per collection
couchbase-capella collection info --collection-name <collection>

# TTL monitoring
couchbase-capella collection ttl-stats --collection-name <collection>
```

### Health Checks
- Document count monitoring
- TTL expiration tracking
- Storage usage per collection
- Query performance metrics

## Migration Strategies

### From Bucket-Only to Scopes/Collections

#### Step 1: Plan Migration
```hcl
# Identify data domains
data_domains = {
  users     = ["user", "profile", "session"]
  orders    = ["order", "payment", "shipping"] 
  analytics = ["event", "metric", "report"]
}
```

#### Step 2: Create Scopes/Collections
```hcl
# Create new structure
new_structure = {
  for domain, collections in data_domains : domain => {
    scope_name = domain
    collections = collections
  }
}
```

#### Step 3: Data Migration
```javascript
// Migrate documents to collections
for (const doc of existingDocs) {
  const targetCollection = determineCollection(doc.type)
  await targetCollection.upsert(doc.id, doc)
}
```

### Best Practices for Migration
1. **Plan thoroughly**: Map existing data to new structure
2. **Gradual migration**: Migrate in phases
3. **Dual writes**: Write to both old and new structure during transition
4. **Validation**: Verify data integrity after migration
5. **Rollback plan**: Prepare for potential rollback

## Troubleshooting

### Common Issues

#### Scope Creation Failed
```
Error: Scope already exists
```
**Solution**: Check existing scopes, use unique names

#### Collection TTL Issues
```
Error: Invalid TTL value
```
**Solution**: Verify TTL is within valid range (0 to 2,147,483,647)

#### Dependency Errors
```
Error: Bucket not found for scope creation
```
**Solution**: Ensure bucket exists before creating scopes

### Debugging Steps

1. **Verify Dependencies**: Check bucket and scope existence
2. **Validate Configuration**: Review scope and collection parameters
3. **Check Permissions**: Verify API token has required permissions
4. **Monitor Creation**: Track resource creation progress

## Best Practices

### Design Principles
- **Logical Separation**: Group related data in same scope
- **Security Boundaries**: Align with access control requirements
- **Performance**: Consider query patterns in design
- **Scalability**: Plan for future growth and changes

### Naming Conventions
```hcl
# Consistent naming patterns
naming_pattern = {
  scope_prefix      = "${var.env}_"
  collection_suffix = "_data"
  separator         = "_"
}

# Example names
scopes = {
  "${var.env}_user_service"
  "${var.env}_order_service"
  "${var.env}_analytics"
}
```

### TTL Management
- Use appropriate TTL for data lifecycle
- Monitor TTL performance impact
- Plan for TTL changes in application logic
- Test TTL behavior in development

### Performance Optimization
- Design collections around query patterns
- Use indexes effectively
- Monitor collection-level performance
- Optimize document structure for collections

## Related Documentation

- [Couchbase Buckets](couchbase-buckets.md) - Bucket configuration and management
- [Couchbase Indexes](couchbase-indexes.md) - Index creation for collections
- [Database Credentials](database-credentials.md) - Access control for collections
- [Couchbase Clusters](couchbase-clusters.md) - Cluster infrastructure 