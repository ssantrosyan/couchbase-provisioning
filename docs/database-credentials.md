# Database Credentials Documentation

This document describes the Couchbase Capella database credentials created and managed by this Terraform configuration.

## Overview

Database credentials provide secure access to Couchbase data with fine-grained permissions. This configuration manages service-specific users with role-based access control, integrating with AWS Secrets Manager for secure credential storage.

## Resource Configuration

**Resource**: `couchbase-capella_database_credential.database_credential`  
**File**: `resources_couchbase_capella_database_credentials.tf`  
**Constants**: `constants_couchbase_permissions.tf`  
**Provider**: `couchbase-capella`

## Credential Structure

### Database Credential Configuration

Credentials are defined in `constants_couchbase_permissions.tf`:

```hcl
couchbase_capella_db_credentials = {
  service_name1_user = {
    access = [
      {
        privileges = ["data_writer", "data_reader"]
        resources = {
          buckets = [
            {
              name = "bucket1"
              scopes = [
                {
                  name = "collection1"
                }
              ]
            }
          ]
        }
      }
    ]
    cluster_name = local.couchbase_cluster_name
    secret_name  = "/${var.env}/service_name1/couchbase-capella"
    cluster_id   = var.couchbase_default_cluster_id
    project_id   = var.couchbase_default_project_id
  }
  
  service_name2_user = {
    access = [
      {
        privileges = ["data_writer", "data_reader", "query_select"]
        resources = {
          buckets = [
            {
              name = "bucket2"
              scopes = [
                {
                  name = "scope2"
                  collections = [
                    {
                      name = "collection2"
                    }
                  ]
                }
              ]
            }
          ]
        }
      }
    ]
    cluster_name = local.couchbase_cluster_name
    secret_name  = "/${var.env}/service_name2/couchbase-capella"
    cluster_id   = var.couchbase_default_cluster_id
    project_id   = var.couchbase_default_project_id
  }
}
```

## Access Control Model

### Privilege Types

#### Data Access Privileges
- **data_reader**: Read access to documents
- **data_writer**: Write/update/delete documents
- **data_dcp_reader**: DCP (Database Change Protocol) read access

#### Query Privileges
- **query_select**: Execute SELECT queries
- **query_update**: Execute UPDATE queries
- **query_insert**: Execute INSERT queries
- **query_delete**: Execute DELETE queries
- **query_manage_index**: Create/drop indexes

#### Bucket Management
- **bucket_admin**: Full bucket administration
- **views_admin**: Manage views and design documents
- **replication_admin**: Manage XDCR replication

#### System Privileges
- **cluster_admin**: Full cluster administration
- **security_admin**: Manage users and security
- **query_system_catalog**: Access system catalog

### Resource Hierarchy

```
Organization
├── Project
    ├── Cluster
        ├── Bucket
            ├── Scope
                ├── Collection
```

Access can be granted at any level in the hierarchy:

#### Bucket-Level Access
```hcl
bucket_access = {
  privileges = ["data_reader", "data_writer"]
  resources = {
    buckets = [
      {
        name = "bucket1"
        # Access to entire bucket
      }
    ]
  }
}
```

#### Scope-Level Access
```hcl
scope_access = {
  privileges = ["data_reader"]
  resources = {
    buckets = [
      {
        name = "bucket1"
        scopes = [
          {
            name = "scope1"
            # Access to all collections in scope
          }
        ]
      }
    ]
  }
}
```

#### Collection-Level Access
```hcl
collection_access = {
  privileges = ["data_writer"]
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
                # Access to specific collection only
              }
            ]
          }
        ]
      }
    ]
  }
}
```

## Service-Specific Credentials

### Microservice Access Patterns

#### User Service
```hcl
user_service_credentials = {
  access = [
    {
      privileges = ["data_reader", "data_writer", "query_select", "query_update"]
      resources = {
        buckets = [
          {
            name = "app_data"
            scopes = [
              {
                name = "user_service"
                collections = [
                  {
                    name = "users"
                  },
                  {
                    name = "profiles"
                  },
                  {
                    name = "sessions"
                  }
                ]
              }
            ]
          }
        ]
      }
    }
  ]
  secret_name = "/${var.env}/user-service/couchbase"
}
```

#### Order Service
```hcl
order_service_credentials = {
  access = [
    {
      privileges = ["data_reader", "data_writer", "query_select", "query_insert"]
      resources = {
        buckets = [
          {
            name = "app_data"
            scopes = [
              {
                name = "order_service"
                collections = [
                  {
                    name = "orders"
                  },
                  {
                    name = "payments"
                  }
                ]
              }
            ]
          }
        ]
      }
    },
    {
      # Read-only access to user data for validation
      privileges = ["data_reader"]
      resources = {
        buckets = [
          {
            name = "app_data"
            scopes = [
              {
                name = "user_service"
                collections = [
                  {
                    name = "users"
                  }
                ]
              }
            ]
          }
        ]
      }
    }
  ]
  secret_name = "/${var.env}/order-service/couchbase"
}
```

#### Analytics Service
```hcl
analytics_service_credentials = {
  access = [
    {
      # Read-only access for analytics
      privileges = ["data_reader", "query_select"]
      resources = {
        buckets = [
          {
            name = "app_data"
            # Access to entire bucket for analytics
          },
          {
            name = "analytics_data"
            # Full access to analytics bucket
            privileges = ["data_reader", "data_writer", "query_select", "query_insert"]
          }
        ]
      }
    }
  ]
  secret_name = "/${var.env}/analytics-service/couchbase"
}
```

## AWS Secrets Manager Integration

### Secret Storage

Credentials are automatically stored in AWS Secrets Manager with the following structure:

```json
{
  "username": "generated-username",
  "password": "generated-password",
  "connection_string": "couchbases://cluster-endpoint",
  "bucket": "bucket-name",
  "scope": "scope-name",
  "collection": "collection-name"
}
```

### Secret Naming Convention

Secrets follow the pattern: `/${environment}/${service}/couchbase-capella`

Examples:
- `/dev/user-service/couchbase-capella` (points to shared dev cluster)
- `/stage/user-service/couchbase-capella` (points to same shared dev cluster)
- `/prod/order-service/couchbase-capella` (points to dedicated prod cluster)

### Access from Applications

#### AWS SDK Example
```python
import boto3
import json

def get_couchbase_credentials(service_name, environment):
    secrets_client = boto3.client('secretsmanager')
    secret_name = f"/{environment}/{service_name}/couchbase-capella"
    
    response = secrets_client.get_secret_value(SecretId=secret_name)
    credentials = json.loads(response['SecretString'])
    
    return credentials

# Usage
creds = get_couchbase_credentials('user-service', 'prod')
cluster = Cluster(creds['connection_string'])
cluster.authenticate(creds['username'], creds['password'])
```

#### Environment Variables
```bash
# Retrieve credentials using AWS CLI
aws secretsmanager get-secret-value \
  --secret-id "/prod/user-service/couchbase-capella" \
  --query 'SecretString' \
  --output text | jq -r '.username'
```

## Cluster Architecture Impact

### Shared vs. Dedicated Clusters

#### Shared Dev Cluster (Dev & Stage)
- **Single Cluster**: Both dev and stage environments use the same cluster
- **Logical Separation**: Data isolation through environment-specific scopes/collections
- **Credential Scope**: Each environment has separate database users but on the same cluster
- **Cost Efficiency**: Shared infrastructure reduces costs for non-production workloads

```hcl
# Dev and stage both reference the same cluster
dev_credentials = {
  cluster_id = "shared-dev-cluster-id"
  scope_name = "dev_user_service"
  collection_name = "dev_users"
}

stage_credentials = {
  cluster_id = "shared-dev-cluster-id"  # Same cluster
  scope_name = "stage_user_service"     # Different scope
  collection_name = "stage_users"       # Different collection
}
```

#### Dedicated Production Cluster
- **Isolated Cluster**: Production has its own dedicated cluster
- **Complete Separation**: No shared resources with dev/stage
- **Enhanced Security**: Physical isolation for production data
- **Independent Scaling**: Production can scale independently

```hcl
prod_credentials = {
  cluster_id = "dedicated-prod-cluster-id"  # Different cluster
  scope_name = "user_service"
  collection_name = "users"
}
```

## Credential Management

### Lifecycle Management

#### Automatic Generation
- **Username**: Auto-generated unique identifier
- **Password**: Strong, randomly generated password
- **Rotation**: Managed through AWS Secrets Manager
- **Expiration**: Configurable through Capella console

#### Manual Operations
```bash
# View credential details
terraform show couchbase-capella_database_credential.database_credential

# Force credential recreation
terraform taint couchbase-capella_database_credential.database_credential["service_name"]
terraform apply
```

### Security Best Practices

#### Password Policies
- **Length**: Minimum 12 characters
- **Complexity**: Mixed case, numbers, special characters
- **Rotation**: Regular rotation schedule
- **No Reuse**: Prevent password reuse

#### Access Control
- **Least Privilege**: Grant minimum required permissions
- **Service Isolation**: Each service has dedicated credentials
- **Environment Separation**: Separate credentials per environment
- **Regular Audit**: Review permissions periodically

## Monitoring and Auditing

### Access Monitoring

#### Login Tracking
```sql
-- Monitor user connections
SELECT * FROM system:user_info WHERE name LIKE 'service_%'

-- Check active sessions
SELECT * FROM system:active_requests WHERE user LIKE 'service_%'
```

#### Permission Verification
```sql
-- Verify user permissions
SELECT * FROM system:user_info WHERE name = 'service_user_name'

-- Check bucket access
SELECT * FROM system:bucket_info WHERE name IN (
  SELECT bucket_name FROM system:user_info WHERE name = 'service_user_name'
)
```

### Audit Logging

#### Couchbase Audit Events
- User authentication events
- Data access operations
- Permission changes
- Query execution logs

#### AWS CloudTrail Integration
- Secrets Manager access logs
- IAM role assumptions
- API call tracking
- Cross-service access patterns

## Troubleshooting

### Common Issues

#### Authentication Failures
```
Error: Authentication failed for user
```
**Solutions**:
1. Verify credentials in AWS Secrets Manager
2. Check user exists in Couchbase
3. Validate network connectivity
4. Review access permissions

#### Permission Denied
```
Error: User does not have permission to access resource
```
**Solutions**:
1. Review user privileges in configuration
2. Check resource hierarchy access
3. Verify bucket/scope/collection names
4. Update access configuration if needed

#### Connection Issues
```
Error: Failed to connect to cluster
```
**Solutions**:
1. Verify cluster endpoint and port
2. Check VPC peering configuration
3. Validate security group rules
4. Test network connectivity

### Debugging Steps

1. **Verify Credentials**: Check AWS Secrets Manager
2. **Test Authentication**: Use Couchbase CLI tools
3. **Check Permissions**: Review user access in console
4. **Network Validation**: Test connectivity to cluster
5. **Audit Logs**: Review authentication and access logs

### Debug Commands

#### Couchbase CLI
```bash
# Test authentication
couchbase-cli user-manage --cluster <cluster> \
  --username <admin-user> --password <admin-pass> \
  --list --rbac-username <service-user>

# Test query access
cbq -e "SELECT * FROM system:user_info WHERE name = 'service_user'"
```

#### AWS CLI
```bash
# Verify secret exists
aws secretsmanager describe-secret \
  --secret-id "/prod/service/couchbase-capella"

# Test secret access
aws secretsmanager get-secret-value \
  --secret-id "/prod/service/couchbase-capella"
```

## Performance Considerations

### Connection Pooling
- **Pool Size**: Configure appropriate connection pool sizes
- **Timeout Settings**: Set reasonable connection timeouts
- **Keep-Alive**: Enable connection keep-alive
- **Monitoring**: Track connection pool metrics

### Query Optimization
- **Prepared Statements**: Use prepared statements for performance
- **Index Usage**: Ensure queries use appropriate indexes
- **Result Limiting**: Limit result sets to reduce network traffic
- **Batch Operations**: Use batch operations where possible

## Best Practices

### Security
1. **Principle of Least Privilege**: Grant minimal necessary permissions
2. **Regular Rotation**: Implement credential rotation policies
3. **Secure Storage**: Use AWS Secrets Manager for credential storage
4. **Network Security**: Implement proper network isolation
5. **Audit Regularly**: Monitor and audit access patterns

### Performance
1. **Connection Management**: Implement proper connection pooling
2. **Query Optimization**: Design efficient queries and indexes
3. **Resource Monitoring**: Track database resource usage
4. **Capacity Planning**: Plan for scaling requirements

### Operational
1. **Documentation**: Document service access patterns
2. **Testing**: Test credentials in non-production environments
3. **Monitoring**: Set up alerts for authentication failures
4. **Backup**: Include credential configuration in backups

### Development
1. **Environment Parity**: Use similar access patterns across environments
2. **Local Development**: Provide development-friendly access methods
3. **Testing**: Include credential testing in CI/CD pipelines
4. **Version Control**: Track credential configuration changes

## Related Documentation

- [AWS Secrets Manager](aws-secrets.md) - Secret storage and retrieval
- [Couchbase Scopes and Collections](couchbase-scopes-collections.md) - Resource hierarchy for access control
- [Couchbase Buckets](couchbase-buckets.md) - Bucket-level access management
- [VPC Peering](vpc-peering.md) - Network connectivity for database access 