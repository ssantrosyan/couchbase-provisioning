# Couchbase Projects Documentation

This document describes the Couchbase Capella projects created and managed by this Terraform configuration.

## Overview

Couchbase Capella projects serve as the organizational containers for clusters, databases, and related resources. Each environment typically has its own dedicated project for isolation and management.

## Resource Configuration

**Resource**: `couchbase-capella_project.project`  
**File**: `resources_couchbase_capella_projects.tf`  
**Provider**: `couchbase-capella`

## Project Structure

### Environment-Based Projects

The project creation is controlled by the `couchbase_project_env` list in `constants.tf`:

```hcl
couchbase_project_env = ["dev", "prod", "stage"]
```

### Project Configuration

#### Project Properties
- **Organization ID**: Environment-specific organization ID from `local.couchbase_org_id`
- **Name**: Descriptive name from `local.env_naming_dict`
- **Description**: Environment-specific description
- **Lifecycle Protection**: `prevent_destroy = true`

## Environment-Specific Settings

### Development Environment
- **Name**: "Company-Development"
- **Organization ID**: From `local.couchbase_org_id["dev"]`
- **Description**: "Company dev cluster"
- **Purpose**: Development and testing
- **Cluster**: Shared dev cluster (manual/free tier)

### Staging Environment
- **Name**: "Company-Staging"
- **Organization ID**: From `local.couchbase_org_id["stage"]`
- **Description**: "Company stage cluster"
- **Purpose**: Pre-production testing
- **Cluster**: Shared dev cluster (same as development)

### Production Environment
- **Name**: "Company-Production"
- **Organization ID**: From `local.couchbase_org_id["prod"]`
- **Description**: "Company prod cluster"
- **Purpose**: Production workloads
- **Cluster**: Dedicated production cluster (automated)

## Configuration Details

### Organization IDs

The organization IDs are defined in `constants.tf` and must be updated with your actual Couchbase organization IDs:

```hcl
couchbase_org_id = {
  dev   = "Your Organization ID in Couchbase"  # Company Org ID
  stage = "Your Organization ID in Couchbase"  # Company Org ID
  prod  = "Your Organization ID in Couchbase"  # Company Org ID
}
```

### Project Naming

Project names follow the pattern defined in `env_naming_dict`:

```hcl
env_naming_dict = {
  dev   = "Company-Development"
  stage = "Company-Staging" 
  prod  = "Company-Production"
}
```

## Resource Dependencies

### Dependent Resources
The following resources depend on the project:

1. **Clusters**: `couchbase-capella_cluster.cluster`
2. **Buckets**: `couchbase-capella_bucket.bucket`
3. **Scopes**: `couchbase-capella_scope.scope`
4. **Collections**: `couchbase-capella_collection.collection`
5. **Indexes**: `couchbase-capella_query_index.index`
6. **Database Credentials**: `couchbase-capella_database_credential.database_credential`

### Reference Pattern
Other resources reference the project using:
```hcl
project_id = couchbase-capella_project.project.0.id
```

## Lifecycle Management

### Protection Rules
- **Prevent Destroy**: Enabled to protect against accidental deletion
- **Manual Intervention**: Required for project deletion

### State Management
- **Count**: Conditional creation based on environment
- **Index**: Always uses index `[0]` when created

## Setup Requirements

### Before Deployment

1. **Organization Access**: Ensure you have admin access to the Couchbase organization
2. **API Token**: Valid Capella API token with project creation permissions
3. **Organization IDs**: Update the organization IDs in `constants.tf`

### Required Permissions

The API token must have the following permissions:
- **Organization**: Read access
- **Projects**: Create, read, update, delete
- **Clusters**: Create, read, update, delete (for dependent resources)

## Terraform Operations

### Create Project
```bash
# Plan project creation
terraform plan -target=couchbase-capella_project.project

# Create project
terraform apply -target=couchbase-capella_project.project
```

### View Project Information
```bash
# Show project state
terraform show couchbase-capella_project.project[0]

# Get project ID
terraform output -raw project_id
```

### Project Dependencies
```bash
# View all dependent resources
terraform state list | grep couchbase-capella

# Plan with project dependencies
terraform plan -target=couchbase-capella_project.project \
  -target=couchbase-capella_cluster.cluster
```

## Monitoring and Management

### Project Status
- Monitor project status through Couchbase Capella console
- Check project quotas and usage
- Review project-level billing and costs

### Health Checks
```bash
# Verify project exists
couchbase-capella project get --project-id <project-id>

# List all projects in organization
couchbase-capella project list --organization-id <org-id>
```

## Troubleshooting

### Common Issues

#### Project Creation Fails
```
Error: Error creating project: insufficient permissions
```
**Solution**: Verify API token has project creation permissions

#### Organization ID Not Found
```
Error: organization not found
```
**Solution**: Verify organization ID in `constants.tf` is correct

#### Project Already Exists
```
Error: project with name already exists
```
**Solution**: Check for existing projects with same name in organization

### Debugging Steps

1. **Verify Organization**: Ensure organization ID is correct
2. **Check API Token**: Verify token permissions and expiration
3. **Review Limits**: Check organization project limits
4. **Console Verification**: Verify in Couchbase Capella console

## Best Practices

### Naming Conventions
- Use consistent naming patterns across environments
- Include company/team identifier in project names
- Use environment-specific suffixes

### Security
- Rotate API tokens regularly
- Use least privilege principle for API permissions
- Monitor project access and modifications

### Cost Management
- Monitor project-level resource usage
- Set up billing alerts for projects
- Regular cleanup of unused resources

### Documentation
- Keep organization IDs updated in documentation
- Document project purpose and ownership
- Maintain environment-specific configuration notes

## Integration Points

### CI/CD Integration
```yaml
# Example GitHub Actions workflow
- name: Deploy Couchbase Project
  run: |
    terraform plan -target=couchbase-capella_project.project
    terraform apply -auto-approve -target=couchbase-capella_project.project
```

### Monitoring Integration
- Set up alerts for project state changes
- Monitor project resource quotas
- Track project-level costs and usage

## Related Documentation

- [Couchbase Clusters](couchbase-clusters.md) - Cluster deployment within projects
- [Database Credentials](database-credentials.md) - User management within projects
- [Couchbase Buckets](couchbase-buckets.md) - Data storage within projects
- [AWS Infrastructure](aws-infrastructure.md) - Supporting AWS infrastructure 