# Couchbase Capella Infrastructure Provisioning

This repository contains Terraform configurations for provisioning and managing Couchbase Capella infrastructure on AWS. The infrastructure supports multiple environments (development, staging, production) with automated provisioning of Couchbase clusters, databases, and associated AWS networking components.

## 🏗️ Architecture Overview

This project provisions:
- **Couchbase Capella**: Projects, clusters, buckets, scopes, collections, indexes, and database credentials
- **AWS Infrastructure**: VPC, subnets, NAT gateways, EIPs, and VPC peering connections
- **Multi-Environment Support**: Separate configurations for dev, stage, and prod environments

## 📁 Project Structure

```
couchbase-provisioning/
├── docs/                              # Detailed resource documentation
├── provisioning/                      # Main Terraform configurations
│   ├── environments/                  # Environment-specific configurations
│   │   ├── dev/                      # Development environment
│   │   ├── stage/                    # Staging environment
│   │   └── prod/                     # Production environment
│   ├── constants_*.tf                # Resource configuration constants
│   ├── resources_*.tf                # Resource definitions
│   ├── variables.tf                  # Input variables
│   ├── _providers.tf                 # Provider configurations
│   └── module_vpc.tf                 # VPC module configuration
└── README.md                         # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Terraform** (>= 1.0)
2. **AWS CLI** configured with appropriate credentials
3. **Couchbase Capella API Token** - Generate from your Couchbase Cloud console
4. Access to AWS account with permissions to create VPCs, subnets, and networking resources

### Environment Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ssantrosyan/couchbase-provisioning.git
   cd couchbase-provisioning/provisioning
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Configure environment variables:**
   ```bash
   export TF_VAR_couchbase_capella_token="your-api-token-here"
   ```

4. **Select and configure your environment:**
   
   For **Development**:
   ```bash
   terraform workspace select dev || terraform workspace new dev
   terraform plan -var-file="environments/dev/dev.tfvars"
   terraform apply -var-file="environments/dev/dev.tfvars"
   ```
   
   For **Staging**:
   ```bash
   terraform workspace select stage || terraform workspace new stage
   terraform plan -var-file="environments/stage/stage.tfvars"
   terraform apply -var-file="environments/stage/stage.tfvars"
   ```
   
   For **Production**:
   ```bash
   terraform workspace select prod || terraform workspace new prod
   terraform plan -var-file="environments/prod/prod.tfvars"
   terraform apply -var-file="environments/prod/prod.tfvars"
   ```

## 🔧 Configuration

### Required Variables

| Variable | Description | Type | Required |
|----------|-------------|------|----------|
| `env` | Environment name (dev/stage/prod) | string | Yes |
| `region` | AWS region | string | Yes |
| `couchbase_capella_token` | Couchbase Capella API token | string (sensitive) | Yes |
| `couchbase_clusters_params` | Cluster configuration parameters | object | No |
| `couchbase_default_cluster_id` | Default cluster ID for manual clusters | string | No |
| `couchbase_default_project_id` | Default project ID for manual clusters | string | No |
| `collection_ttl_configuration` | TTL configuration for collections | object | No |

### Environment-Specific Configuration

Each environment has its own configuration file in `environments/{env}/{env}.tfvars`:

- **Dev**: Uses shared manual cluster (free tier) for development
- **Stage**: Uses the same shared dev cluster for staging/testing
- **Prod**: Dedicated production cluster with high availability settings

## 📊 Resources Created

### Couchbase Capella Resources
- **Projects**: Environment-specific Couchbase projects
- **Clusters**: Couchbase clusters with configurable specifications
- **Buckets**: Data storage buckets with memory allocation
- **Scopes**: Logical groupings within buckets
- **Collections**: Data collections with TTL configurations
- **Indexes**: Query performance indexes
- **Database Credentials**: Service-specific access credentials
- **VPC Peering**: Network connectivity between AWS VPC and Couchbase

### AWS Infrastructure
- **VPC**: Virtual private cloud with public/private subnets
- **Subnets**: Public and private subnets across multiple AZs
- **NAT Gateway**: Outbound internet access for private subnets
- **Elastic IP**: Static IP for NAT gateway
- **Route Tables**: Routing configuration for subnets
- **Security Groups**: Network security rules

## 🔒 Security Features

- **Sensitive Variables**: API tokens are marked as sensitive
- **Access Control**: Fine-grained database credentials with specific privileges
- **Network Isolation**: Private subnets with controlled outbound access
- **VPC Peering**: Secure connectivity between AWS and Couchbase networks
- **Resource Protection**: Lifecycle rules to prevent accidental deletion

## 🌍 Multi-Environment Support

The project supports three environments with different cluster configurations:

- **Development**: Minimal resources on shared dev cluster (free tier)
- **Staging**: Testing environment on shared dev cluster for cost efficiency
- **Production**: Dedicated production cluster with high availability, replicas, and production-grade settings

## 📚 Documentation

Detailed documentation for each resource type is available in the `docs/` folder:

- [AWS Infrastructure](docs/aws-infrastructure.md)
- [Couchbase Projects](docs/couchbase-projects.md)
- [Couchbase Clusters](docs/couchbase-clusters.md)
- [Couchbase Buckets](docs/couchbase-buckets.md)
- [Couchbase Scopes and Collections](docs/couchbase-scopes-collections.md)
- [Couchbase Indexes](docs/couchbase-indexes.md)
- [Database Credentials](docs/database-credentials.md)
- [VPC Peering](docs/vpc-peering.md)
- [AWS Secrets Manager](docs/aws-secrets.md)

## 🚨 Important Notes

1. **Resource Protection**: Critical resources have `prevent_destroy = true` lifecycle rules
2. **Cost Management**: Review cluster specifications before applying to production
3. **API Limits**: Be aware of Couchbase Capella API rate limits
4. **State Management**: Use remote state storage for team environments
5. **Credentials**: Never commit sensitive credentials to version control

## 🤝 Contributing

1. Create a feature branch from `main`
2. Make your changes
3. Test in development environment
4. Submit a pull request with detailed description

## 📝 License

This project is maintained by [ssantrosyan](https://github.com/ssantrosyan).

## 🆘 Support

For issues related to:
- **Terraform**: Check Terraform documentation
- **Couchbase Capella**: Refer to Couchbase Capella documentation
- **AWS**: Consult AWS documentation
- **This Project**: Open an issue in this repository

---

**⚠️ Warning**: This infrastructure provisioning can incur costs on both AWS and Couchbase Capella. Always review the planned changes before applying and monitor your cloud spending.
