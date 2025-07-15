# VPC Peering Documentation

This document describes the VPC peering configuration between AWS VPC and Couchbase Capella for secure network connectivity.

## Overview

VPC peering establishes a private network connection between your AWS VPC and Couchbase Capella clusters, enabling secure communication without exposing traffic to the public internet. This configuration provides encrypted, low-latency connectivity for database operations.

## Resource Configuration

**Resource**: `couchbase-capella_allowlist.allowlist`  
**File**: `resources_couchbase_capella_peering.tf`  
**Provider**: `couchbase-capella`

## VPC Peering Architecture

### Network Topology

```
AWS VPC (10.0.0.0/16)
├── Public Subnets (10.0.101.0/24, 10.0.102.0/24, 10.0.103.0/24)
├── Private Subnets (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
└── VPC Peering Connection
    │
    └── Couchbase Capella Cluster
        └── Capella VPC (10.x.x.x/20)
```

### Connectivity Flow
1. **Application** → **AWS Private Subnet**
2. **Private Subnet** → **VPC Peering**
3. **VPC Peering** → **Couchbase Capella**
4. **Response Path**: Reverse of above

## Peering Configuration

### Allowlist Resource

The peering is configured using Couchbase Capella allowlist:

```hcl
resource "couchbase-capella_allowlist" "allowlist" {
  for_each        = local.couchbase_allowlist_config
  organization_id = local.couchbase_org_id[var.env]
  project_id      = lookup(each.value, "project_id", var.couchbase_default_project_id)
  cluster_id      = lookup(each.value, "cluster_id", var.couchbase_default_cluster_id)
  cidr_block      = each.value.cidr_block
  comment         = lookup(each.value, "comment", "")
}
```

### Allowlist Configuration

Defined in constants or variables:

```hcl
couchbase_allowlist_config = {
  aws_vpc_peering = {
    cidr_block = "10.0.0.0/16"  # AWS VPC CIDR
    comment    = "AWS VPC peering for ${var.env} environment"
    project_id = var.couchbase_default_project_id
    cluster_id = var.couchbase_default_cluster_id
  }
}
```

### Environment-Specific Configuration

#### Development & Staging (Shared Cluster)
```hcl
# Dev and stage environments share the same cluster
shared_dev_allowlist = {
  cidr_block = "10.0.0.0/16"
  comment    = "Shared dev cluster VPC access for dev and stage environments"
}
```

#### Production (Dedicated Cluster)
```hcl
# Production environment has its own cluster
prod_allowlist = {
  cidr_block = "10.0.1.0/24"  # Private subnets only
  comment    = "Dedicated production cluster VPC access"
}
```

## Network Security

### CIDR Block Planning

#### AWS VPC CIDRs
- **Development**: `10.0.0.0/16`
- **Staging**: `10.1.0.0/16` 
- **Production**: `10.2.0.0/16`

#### Couchbase Capella CIDRs
- **Cluster CIDR**: Specified during cluster creation
- **No Overlap**: Ensure no CIDR conflicts
- **Reserved Ranges**: Avoid commonly used ranges

### Security Groups

#### AWS Security Group Rules
```hcl
# Outbound to Couchbase Capella
resource "aws_security_group_rule" "couchbase_outbound" {
  type              = "egress"
  from_port         = 11207
  to_port           = 11207
  protocol          = "tcp"
  cidr_blocks       = ["10.x.x.x/20"]  # Capella cluster CIDR
  security_group_id = aws_security_group.app_sg.id
}

# Outbound HTTPS for management
resource "aws_security_group_rule" "couchbase_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.x.x.x/20"]
  security_group_id = aws_security_group.app_sg.id
}
```

#### Required Ports

| Port | Protocol | Purpose | Direction |
|------|----------|---------|-----------|
| 11207 | TCP | Couchbase SDK (SSL) | Outbound |
| 443 | TCP | HTTPS Management | Outbound |
| 18091 | TCP | Admin Console (Optional) | Outbound |
| 8093 | TCP | Query Service (Optional) | Outbound |

### Network Access Control Lists (NACLs)

#### Private Subnet NACLs
```hcl
# Allow outbound to Couchbase
resource "aws_network_acl_rule" "couchbase_outbound" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  from_port      = 11207
  to_port        = 11207
  cidr_block     = "10.x.x.x/20"  # Capella CIDR
}

# Allow return traffic
resource "aws_network_acl_rule" "couchbase_inbound_response" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 101
  protocol       = "tcp"
  rule_action    = "allow"
  from_port      = 1024
  to_port        = 65535
  cidr_block     = "10.x.x.x/20"
}
```

## Connection Establishment

### Peering Process

#### 1. Couchbase Capella Setup
```bash
# Add allowlist entry via Capella console or API
couchbase-capella allowlist create \
  --cluster-id <cluster-id> \
  --cidr-block "10.0.0.0/16" \
  --comment "AWS VPC peering"
```

#### 2. AWS VPC Configuration
```bash
# Update route tables to include Capella CIDR
aws ec2 create-route \
  --route-table-id <private-route-table-id> \
  --destination-cidr-block "10.x.x.x/20" \
  --vpc-peering-connection-id <peering-connection-id>
```

#### 3. Security Group Updates
```bash
# Add outbound rules for Couchbase ports
aws ec2 authorize-security-group-egress \
  --group-id <security-group-id> \
  --protocol tcp \
  --port 11207 \
  --cidr "10.x.x.x/20"
```

### Verification Steps

#### Network Connectivity
```bash
# Test connectivity from private subnet
# (requires EC2 instance in private subnet)
telnet <capella-cluster-endpoint> 11207

# Test DNS resolution
nslookup <capella-cluster-endpoint>

# Test HTTPS connectivity
curl -I https://<capella-cluster-endpoint>:18091
```

#### Application Testing
```python
# Test Couchbase connection
from couchbase.cluster import Cluster
from couchbase.auth import PasswordAuthenticator

cluster = Cluster("couchbases://<cluster-endpoint>")
authenticator = PasswordAuthenticator("<username>", "<password>")
cluster.authenticate(authenticator)

# Test basic operations
bucket = cluster.bucket("<bucket-name>")
collection = bucket.default_collection()

# Insert test document
collection.upsert("test-key", {"message": "VPC peering test"})

# Retrieve test document
result = collection.get("test-key")
print(result.content)
```

## Performance Optimization

### Connection Parameters

#### SDK Configuration
```python
# Optimized connection settings for VPC peering
from couchbase.cluster import Cluster
from couchbase.options import ClusterOptions
from datetime import timedelta

options = ClusterOptions(
    # Connection timeouts
    connect_timeout=timedelta(seconds=10),
    kv_timeout=timedelta(seconds=5),
    query_timeout=timedelta(seconds=30),
    
    # Connection pool settings
    max_http_connections=10,
    idle_http_connection_timeout=timedelta(seconds=30),
    
    # Network optimization
    tcp_keep_alive_interval=timedelta(seconds=30),
    config_poll_interval=timedelta(seconds=60)
)

cluster = Cluster("couchbases://<endpoint>", options)
```

#### Connection Pooling
```java
// Java SDK connection optimization
ClusterEnvironment env = ClusterEnvironment.builder()
    .timeoutConfig(timeout -> timeout
        .connectTimeout(Duration.ofSeconds(10))
        .kvTimeout(Duration.ofSeconds(5)))
    .ioConfig(io -> io
        .numKvConnections(4)
        .maxHttpConnections(10))
    .build();

Cluster cluster = Cluster.connect("<endpoint>", env);
```

### Latency Optimization

#### Regional Placement
- **Same Region**: Place AWS VPC and Capella cluster in same region
- **Availability Zones**: Consider AZ placement for latency
- **Network Path**: Minimize network hops

#### Connection Management
- **Connection Reuse**: Implement proper connection pooling
- **Keep-Alive**: Enable TCP keep-alive settings
- **Batch Operations**: Use bulk operations where possible

## Monitoring and Troubleshooting

### Network Monitoring

#### AWS CloudWatch Metrics
```bash
# Monitor VPC traffic
aws cloudwatch get-metric-statistics \
  --namespace AWS/VPC \
  --metric-name NetworkPacketsIn \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 300 \
  --statistics Sum
```

#### VPC Flow Logs
```bash
# Enable VPC Flow Logs for troubleshooting
aws ec2 create-flow-logs \
  --vpc-id <vpc-id> \
  --resource-type VPC \
  --traffic-type ALL \
  --log-destination-type cloud-watch-logs \
  --log-group-name /aws/vpc/flowlogs
```

### Connection Diagnostics

#### Network Path Testing
```bash
# Test routing to Capella cluster
traceroute <capella-cluster-endpoint>

# Check DNS resolution
dig <capella-cluster-endpoint>

# Test specific ports
nc -zv <capella-cluster-endpoint> 11207
nc -zv <capella-cluster-endpoint> 443
```

#### Couchbase Diagnostics
```bash
# SDK diagnostics
couchbase-cli collect-logs-start \
  --cluster <endpoint> \
  --username <admin-user> \
  --password <admin-pass>

# Connection test
cbq -e "SELECT 1" \
  --engine <endpoint> \
  --user <username> \
  --password <password>
```

## Troubleshooting Common Issues

### Connection Timeouts

#### Symptoms
```
Error: Connection timeout to cluster
TimeoutException: Operation timed out
```

#### Solutions
1. **Check Security Groups**: Verify outbound rules allow Couchbase ports
2. **Verify Route Tables**: Ensure routes to Capella CIDR exist
3. **Test Network Path**: Use traceroute and telnet for diagnosis
4. **Review NACLs**: Check Network ACL rules aren't blocking traffic

### DNS Resolution Issues

#### Symptoms
```
Error: Failed to resolve hostname
UnknownHostException: cluster-endpoint.com
```

#### Solutions
1. **DNS Configuration**: Ensure VPC has DNS resolution enabled
2. **Security Groups**: Allow outbound DNS (port 53)
3. **Route53**: Consider using Route53 private hosted zones
4. **Custom DNS**: Configure custom DNS servers if needed

### SSL/TLS Errors

#### Symptoms
```
Error: SSL handshake failed
CertificateException: Certificate validation failed
```

#### Solutions
1. **Certificate Validation**: Ensure proper certificate validation
2. **SSL Configuration**: Use correct SSL settings in SDK
3. **Time Synchronization**: Verify system time is accurate
4. **CA Certificates**: Ensure CA certificates are up to date

### Performance Issues

#### Symptoms
```
Error: High latency operations
Slow query performance
Connection pool exhaustion
```

#### Solutions
1. **Network Path**: Optimize routing between VPC and Capella
2. **Connection Pooling**: Implement proper connection management
3. **Regional Placement**: Ensure same-region deployment
4. **Bandwidth**: Monitor and scale network capacity

## Best Practices

### Security
1. **Minimal CIDR Blocks**: Use smallest necessary CIDR ranges
2. **Private Subnets**: Route traffic through private subnets only
3. **Security Groups**: Implement least privilege access
4. **Regular Audits**: Review and audit network access regularly

### Performance
1. **Same Region**: Deploy in same AWS region as Capella cluster
2. **Connection Pooling**: Implement efficient connection management
3. **Batch Operations**: Use bulk operations to reduce round trips
4. **Monitor Latency**: Track and optimize network performance

### Operational
1. **Documentation**: Document network architecture and dependencies
2. **Testing**: Test connectivity during deployments
3. **Monitoring**: Set up alerts for connectivity issues
4. **Backup Connectivity**: Consider multiple connectivity options

### Cost Optimization
1. **Traffic Patterns**: Monitor and optimize data transfer patterns
2. **Regional Strategy**: Consider data transfer costs between regions
3. **Connection Efficiency**: Optimize connection usage to reduce costs
4. **Reserved Capacity**: Consider reserved capacity for predictable workloads

## Related Documentation

- [AWS Infrastructure](aws-infrastructure.md) - VPC and networking setup
- [Couchbase Clusters](couchbase-clusters.md) - Cluster network configuration
- [Database Credentials](database-credentials.md) - Secure access over peering
- [AWS Secrets Manager](aws-secrets.md) - Credential management for connections 