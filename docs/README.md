# Documentation

This directory contains comprehensive documentation for the Couchbase provisioning infrastructure and configuration.

## Documentation Structure

### AWS Infrastructure
- **[aws-infrastructure.md](aws-infrastructure.md)** - Overview of AWS infrastructure components and architecture
- **[aws-secrets.md](aws-secrets.md)** - Documentation for AWS Secrets Manager integration and secret management
- **[vpc-peering.md](vpc-peering.md)** - VPC peering configuration and network connectivity setup

### Couchbase Components
- **[couchbase-clusters.md](couchbase-clusters.md)** - Couchbase cluster provisioning and configuration
- **[couchbase-projects.md](couchbase-projects.md)** - Couchbase project setup and management
- **[couchbase-buckets.md](couchbase-buckets.md)** - Bucket creation, configuration, and management
- **[couchbase-scopes-collections.md](couchbase-scopes-collections.md)** - Scopes and collections structure and organization
- **[couchbase-indexes.md](couchbase-indexes.md)** - Index creation and optimization strategies

### Security & Access
- **[database-credentials.md](database-credentials.md)** - Database user management and credential configuration

## Getting Started

1. Start with [aws-infrastructure.md](aws-infrastructure.md) to understand the overall architecture
2. Review [couchbase-clusters.md](couchbase-clusters.md) for cluster setup
3. Configure your data structure using the buckets, scopes, and collections documentation
4. Set up appropriate security using the credentials and secrets documentation

## Quick Reference

| Component | Documentation | Purpose |
|-----------|--------------|---------|
| Infrastructure | aws-infrastructure.md | Base AWS setup |
| Networking | vpc-peering.md | Network connectivity |
| Security | aws-secrets.md, database-credentials.md | Secret and credential management |
| Database | couchbase-*.md files | Couchbase configuration and setup |
