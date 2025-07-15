# AWS Secrets Manager Documentation

This document describes the AWS Secrets Manager integration for storing and managing Couchbase Capella database credentials securely.

## Overview

AWS Secrets Manager provides secure storage, automatic rotation, and fine-grained access control for Couchbase database credentials. This integration ensures that sensitive credentials are never hardcoded in applications or configuration files.

## Resource Configuration

**Resource**: `aws_secretsmanager_secret.couchbase_secret`  
**File**: `resources_couchbase_capella_aws_secrets.tf`  
**Provider**: `aws`

## Secret Structure

### Secret Organization

Secrets are organized by environment and service:

```
AWS Secrets Manager
├── /dev/service_name1/couchbase-capella
├── /dev/service_name2/couchbase-capella
├── /stage/service_name1/couchbase-capella
├── /stage/service_name2/couchbase-capella
├── /prod/service_name1/couchbase-capella
└── /prod/service_name2/couchbase-capella
```

### Secret Content Format

Each secret contains the following JSON structure:

```json
{
  "username": "couchbase-generated-username",
  "password": "secure-generated-password",
  "connection_string": "couchbases://cluster-endpoint.cloud.couchbase.com",
  "bucket": "bucket1",
  "scope": "scope1", 
  "collection": "collection1",
  "cluster_id": "cluster-uuid",
  "project_id": "project-uuid",
  "created_date": "2024-01-01T12:00:00Z",
  "environment": "prod",
  "service": "service_name1"
}
```

## Secret Configuration

### Terraform Resource Definition

```hcl
resource "aws_secretsmanager_secret" "couchbase_secret" {
  for_each                = local.couchbase_capella_db_credentials
  name                    = each.value.secret_name
  description             = "Couchbase Capella credentials for ${each.key} in ${var.env} environment"
  recovery_window_in_days = var.env == "prod" ? 30 : 0

  tags = merge(local.tags, {
    Service     = each.key
    SecretType  = "couchbase-credentials"
    Environment = var.env
  })
}

resource "aws_secretsmanager_secret_version" "couchbase_secret_version" {
  for_each  = local.couchbase_capella_db_credentials
  secret_id = aws_secretsmanager_secret.couchbase_secret[each.key].id
  
  secret_string = jsonencode({
    username          = couchbase-capella_database_credential.database_credential[each.key].username
    password          = couchbase-capella_database_credential.database_credential[each.key].password
    connection_string = "couchbases://${couchbase-capella_cluster.cluster[0].connection_string}"
    bucket           = each.value.bucket_name
    scope            = each.value.scope_name
    collection       = each.value.collection_name
    cluster_id       = each.value.cluster_id
    project_id       = each.value.project_id
    created_date     = timestamp()
    environment      = var.env
    service          = each.key
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
```

### Environment-Specific Configuration

#### Development
```hcl
dev_secrets = {
  recovery_window_in_days = 0  # Immediate deletion for dev
  enable_rotation         = false
  automatic_rotation      = null
}
```

#### Production
```hcl
prod_secrets = {
  recovery_window_in_days = 30  # 30-day recovery window
  enable_rotation         = true
  automatic_rotation = {
    automatically_after_days = 90
    rotation_lambda_arn     = aws_lambda_function.rotation.arn
  }
}
```

## Access Control

### IAM Policies

#### Application Access Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:*:*:secret:/prod/user-service/couchbase-capella-*",
        "arn:aws:secretsmanager:*:*:secret:/prod/order-service/couchbase-capella-*"
      ]
    }
  ]
}
```

#### Service-Specific Access
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:/prod/user-service/couchbase-capella-*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalTag/Service": "user-service"
        }
      }
    }
  ]
}
```

#### Admin Management Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:UpdateSecret",
        "secretsmanager:DeleteSecret",
        "secretsmanager:RotateSecret",
        "secretsmanager:TagResource",
        "secretsmanager:UntagResource"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:/*/couchbase-capella-*"
    }
  ]
}
```

### IAM Roles

#### ECS Task Role
```hcl
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.env}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_access" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.couchbase_secrets_access.arn
}
```

#### Lambda Execution Role
```hcl
resource "aws_iam_role" "lambda_secrets_role" {
  name = "${var.env}-lambda-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
```

## Application Integration

### SDK Usage Examples

#### Python (Boto3)
```python
import boto3
import json
from couchbase.cluster import Cluster
from couchbase.auth import PasswordAuthenticator

class CouchbaseConnection:
    def __init__(self, service_name, environment):
        self.secrets_client = boto3.client('secretsmanager')
        self.service_name = service_name
        self.environment = environment
        self._cluster = None
        self._credentials = None

    def get_credentials(self):
        if not self._credentials:
            secret_name = f"/{self.environment}/{self.service_name}/couchbase-capella"
            
            try:
                response = self.secrets_client.get_secret_value(SecretId=secret_name)
                self._credentials = json.loads(response['SecretString'])
            except Exception as e:
                raise Exception(f"Failed to retrieve credentials: {str(e)}")
        
        return self._credentials

    def get_cluster(self):
        if not self._cluster:
            creds = self.get_credentials()
            
            # Initialize cluster connection
            self._cluster = Cluster(creds['connection_string'])
            
            # Authenticate
            authenticator = PasswordAuthenticator(
                creds['username'], 
                creds['password']
            )
            self._cluster.authenticate(authenticator)
        
        return self._cluster

    def get_collection(self):
        cluster = self.get_cluster()
        creds = self.get_credentials()
        
        bucket = cluster.bucket(creds['bucket'])
        scope = bucket.scope(creds['scope'])
        collection = scope.collection(creds['collection'])
        
        return collection

# Usage example
def main():
    # Initialize connection
    cb_conn = CouchbaseConnection('user-service', 'prod')
    
    # Get collection for operations
    collection = cb_conn.get_collection()
    
    # Perform operations
    collection.upsert('user:123', {'name': 'John Doe', 'email': 'john@example.com'})
    result = collection.get('user:123')
    print(result.content)

if __name__ == "__main__":
    main()
```

#### Node.js
```javascript
const AWS = require('aws-sdk');
const couchbase = require('couchbase');

class CouchbaseConnection {
    constructor(serviceName, environment) {
        this.secretsManager = new AWS.SecretsManager();
        this.serviceName = serviceName;
        this.environment = environment;
        this.cluster = null;
        this.credentials = null;
    }

    async getCredentials() {
        if (!this.credentials) {
            const secretName = `/${this.environment}/${this.serviceName}/couchbase-capella`;
            
            try {
                const response = await this.secretsManager.getSecretValue({
                    SecretId: secretName
                }).promise();
                
                this.credentials = JSON.parse(response.SecretString);
            } catch (error) {
                throw new Error(`Failed to retrieve credentials: ${error.message}`);
            }
        }
        
        return this.credentials;
    }

    async getCluster() {
        if (!this.cluster) {
            const creds = await this.getCredentials();
            
            // Connect to cluster
            this.cluster = await couchbase.connect(creds.connection_string, {
                username: creds.username,
                password: creds.password,
            });
        }
        
        return this.cluster;
    }

    async getCollection() {
        const cluster = await this.getCluster();
        const creds = await this.getCredentials();
        
        const bucket = cluster.bucket(creds.bucket);
        const scope = bucket.scope(creds.scope);
        const collection = scope.collection(creds.collection);
        
        return collection;
    }
}

// Usage example
async function main() {
    try {
        // Initialize connection
        const cbConn = new CouchbaseConnection('user-service', 'prod');
        
        // Get collection
        const collection = await cbConn.getCollection();
        
        // Perform operations
        await collection.upsert('user:123', {
            name: 'John Doe',
            email: 'john@example.com'
        });
        
        const result = await collection.get('user:123');
        console.log(result.content);
    } catch (error) {
        console.error('Error:', error.message);
    }
}

main();
```

#### Java
```java
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;
import com.couchbase.client.java.Cluster;
import com.couchbase.client.java.Collection;
import com.fasterxml.jackson.databind.ObjectMapper;

public class CouchbaseConnection {
    private final SecretsManagerClient secretsClient;
    private final String serviceName;
    private final String environment;
    private Cluster cluster;
    private Map<String, Object> credentials;

    public CouchbaseConnection(String serviceName, String environment) {
        this.secretsClient = SecretsManagerClient.create();
        this.serviceName = serviceName;
        this.environment = environment;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> getCredentials() {
        if (credentials == null) {
            String secretName = String.format("/%s/%s/couchbase-capella", 
                environment, serviceName);
            
            GetSecretValueRequest request = GetSecretValueRequest.builder()
                .secretId(secretName)
                .build();
                
            GetSecretValueResponse response = secretsClient.getSecretValue(request);
            
            try {
                ObjectMapper mapper = new ObjectMapper();
                credentials = mapper.readValue(response.secretString(), Map.class);
            } catch (Exception e) {
                throw new RuntimeException("Failed to parse credentials", e);
            }
        }
        
        return credentials;
    }

    public Cluster getCluster() {
        if (cluster == null) {
            Map<String, Object> creds = getCredentials();
            
            cluster = Cluster.connect(
                (String) creds.get("connection_string"),
                (String) creds.get("username"),
                (String) creds.get("password")
            );
        }
        
        return cluster;
    }

    public Collection getCollection() {
        Cluster cluster = getCluster();
        Map<String, Object> creds = getCredentials();
        
        return cluster
            .bucket((String) creds.get("bucket"))
            .scope((String) creds.get("scope"))
            .collection((String) creds.get("collection"));
    }
}
```

### Environment Variables Integration

#### Docker/ECS Environment
```dockerfile
# Dockerfile with AWS CLI for secret retrieval
FROM amazonlinux:2

RUN yum install -y aws-cli jq

# Copy application
COPY app/ /app/

# Entrypoint script to fetch secrets
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["java", "-jar", "/app/application.jar"]
```

#### Entrypoint Script
```bash
#!/bin/bash
# entrypoint.sh

set -e

# Fetch Couchbase credentials
SECRET_NAME="/${ENVIRONMENT}/${SERVICE_NAME}/couchbase-capella"
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --query 'SecretString' \
  --output text)

# Export as environment variables
export COUCHBASE_USERNAME=$(echo "$SECRET_JSON" | jq -r '.username')
export COUCHBASE_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')
export COUCHBASE_CONNECTION_STRING=$(echo "$SECRET_JSON" | jq -r '.connection_string')
export COUCHBASE_BUCKET=$(echo "$SECRET_JSON" | jq -r '.bucket')
export COUCHBASE_SCOPE=$(echo "$SECRET_JSON" | jq -r '.scope')
export COUCHBASE_COLLECTION=$(echo "$SECRET_JSON" | jq -r '.collection')

# Execute the main command
exec "$@"
```

## Secret Rotation

### Automatic Rotation

#### Lambda Rotation Function
```python
import boto3
import json
import os
from couchbase_capella_client import CapellaClient

def lambda_handler(event, context):
    """
    AWS Lambda function for rotating Couchbase credentials
    """
    secrets_client = boto3.client('secretsmanager')
    secret_arn = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    
    try:
        if step == "createSecret":
            create_new_secret(secrets_client, secret_arn, token)
        elif step == "setSecret":
            set_secret(secrets_client, secret_arn, token)
        elif step == "testSecret":
            test_secret(secrets_client, secret_arn, token)
        elif step == "finishSecret":
            finish_secret(secrets_client, secret_arn, token)
            
        return {"statusCode": 200}
    except Exception as e:
        print(f"Rotation failed: {str(e)}")
        return {"statusCode": 500, "body": str(e)}

def create_new_secret(secrets_client, secret_arn, token):
    """Create new credentials in Couchbase Capella"""
    # Get current secret
    current_secret = secrets_client.get_secret_value(
        SecretId=secret_arn,
        VersionStage="AWSCURRENT"
    )
    
    current_creds = json.loads(current_secret['SecretString'])
    
    # Create new user in Couchbase Capella
    capella_client = CapellaClient(
        api_token=os.environ['CAPELLA_API_TOKEN']
    )
    
    new_user = capella_client.create_database_user(
        cluster_id=current_creds['cluster_id'],
        project_id=current_creds['project_id'],
        permissions=current_creds['permissions']
    )
    
    # Store new credentials as pending
    new_secret = current_creds.copy()
    new_secret['username'] = new_user['username']
    new_secret['password'] = new_user['password']
    
    secrets_client.put_secret_value(
        SecretId=secret_arn,
        ClientRequestToken=token,
        SecretString=json.dumps(new_secret),
        VersionStages=['AWSPENDING']
    )
```

#### Rotation Configuration
```hcl
resource "aws_secretsmanager_secret_rotation" "couchbase_rotation" {
  for_each = var.env == "prod" ? local.couchbase_capella_db_credentials : {}
  
  secret_id           = aws_secretsmanager_secret.couchbase_secret[each.key].id
  rotation_lambda_arn = aws_lambda_function.couchbase_rotation.arn
  
  rotation_rules {
    automatically_after_days = 90
  }

  depends_on = [aws_lambda_permission.allow_secret_manager_call_lambda]
}
```

### Manual Rotation

#### CLI-Based Rotation
```bash
#!/bin/bash
# rotate-couchbase-secret.sh

SECRET_NAME="/prod/user-service/couchbase-capella"
ENVIRONMENT="prod"
SERVICE_NAME="user-service"

# Start rotation
aws secretsmanager rotate-secret \
  --secret-id "$SECRET_NAME" \
  --force-rotate-immediately

# Monitor rotation status
while true; do
  STATUS=$(aws secretsmanager describe-secret \
    --secret-id "$SECRET_NAME" \
    --query 'RotationEnabled' \
    --output text)
  
  if [ "$STATUS" = "True" ]; then
    echo "Rotation in progress..."
    sleep 30
  else
    echo "Rotation completed"
    break
  fi
done

# Verify new credentials
NEW_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --query 'SecretString' \
  --output text)

echo "New credentials: $NEW_SECRET"
```

## Monitoring and Auditing

### CloudWatch Metrics

#### Secret Access Monitoring
```python
import boto3
from datetime import datetime, timedelta

def monitor_secret_access():
    cloudwatch = boto3.client('cloudwatch')
    
    # Custom metric for secret access
    cloudwatch.put_metric_data(
        Namespace='CouchbaseSecrets',
        MetricData=[
            {
                'MetricName': 'SecretAccess',
                'Dimensions': [
                    {
                        'Name': 'SecretName',
                        'Value': '/prod/user-service/couchbase-capella'
                    },
                    {
                        'Name': 'Service',
                        'Value': 'user-service'
                    }
                ],
                'Timestamp': datetime.utcnow(),
                'Value': 1.0,
                'Unit': 'Count'
            }
        ]
    )
```

#### CloudWatch Alarms
```hcl
resource "aws_cloudwatch_metric_alarm" "secret_access_anomaly" {
  alarm_name          = "${var.env}-couchbase-secret-access-anomaly"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SecretAccess"
  namespace           = "CouchbaseSecrets"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "Unusual secret access pattern detected"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    SecretName = "/prod/user-service/couchbase-capella"
  }

  tags = local.tags
}
```

### Audit Logging

#### CloudTrail Integration
```json
{
  "eventVersion": "1.05",
  "userIdentity": {
    "type": "AssumedRole",
    "principalId": "AROABC123DEFGHIJKLMN:user-service-task",
    "arn": "arn:aws:sts::123456789012:assumed-role/user-service-role/user-service-task"
  },
  "eventTime": "2024-01-01T12:00:00Z",
  "eventSource": "secretsmanager.amazonaws.com",
  "eventName": "GetSecretValue",
  "sourceIPAddress": "10.0.1.100",
  "resources": [
    {
      "ARN": "arn:aws:secretsmanager:us-west-2:123456789012:secret:/prod/user-service/couchbase-capella-AbCdEf",
      "accountId": "123456789012"
    }
  ]
}
```

#### Custom Audit Logging
```python
import boto3
import json
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AuditedSecretsClient:
    def __init__(self, service_name, environment):
        self.secrets_client = boto3.client('secretsmanager')
        self.service_name = service_name
        self.environment = environment
        self.cloudwatch = boto3.client('logs')
        
    def get_secret_value(self, secret_id):
        # Log access attempt
        self._log_access_attempt(secret_id)
        
        try:
            response = self.secrets_client.get_secret_value(SecretId=secret_id)
            self._log_access_success(secret_id)
            return response
        except Exception as e:
            self._log_access_failure(secret_id, str(e))
            raise
    
    def _log_access_attempt(self, secret_id):
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'event': 'secret_access_attempt',
            'secret_id': secret_id,
            'service': self.service_name,
            'environment': self.environment
        }
        
        self._send_to_cloudwatch(log_entry)
        logger.info(f"Secret access attempt: {secret_id}")
    
    def _send_to_cloudwatch(self, log_entry):
        self.cloudwatch.put_log_events(
            logGroupName=f'/aws/secrets/{self.environment}',
            logStreamName=f'{self.service_name}-access',
            logEvents=[
                {
                    'timestamp': int(datetime.utcnow().timestamp() * 1000),
                    'message': json.dumps(log_entry)
                }
            ]
        )
```

## Best Practices

### Security
1. **Least Privilege**: Grant minimal necessary permissions for secret access
2. **Regular Rotation**: Implement automatic credential rotation
3. **Audit Trails**: Enable comprehensive logging and monitoring
4. **Network Security**: Access secrets only from authorized networks
5. **Encryption**: Use KMS encryption for secrets at rest

### Performance
1. **Caching**: Cache credentials appropriately (with TTL)
2. **Connection Pooling**: Reuse connections to avoid repeated secret fetches
3. **Regional Placement**: Use Secrets Manager in same region as applications
4. **Batch Operations**: Minimize individual secret requests

### Operational
1. **Monitoring**: Set up alerts for secret access anomalies
2. **Documentation**: Document secret naming conventions and access patterns
3. **Testing**: Include secret access in application testing
4. **Backup**: Ensure secrets are included in disaster recovery plans

### Development
1. **Environment Parity**: Use similar secret structures across environments
2. **Local Development**: Provide secure methods for local development
3. **CI/CD Integration**: Securely handle secrets in deployment pipelines
4. **Version Control**: Never commit secrets to version control

## Related Documentation

- [Database Credentials](database-credentials.md) - Couchbase credential management
- [VPC Peering](vpc-peering.md) - Network connectivity for database access
- [AWS Infrastructure](aws-infrastructure.md) - Supporting AWS infrastructure
- [Couchbase Clusters](couchbase-clusters.md) - Cluster configuration and access 