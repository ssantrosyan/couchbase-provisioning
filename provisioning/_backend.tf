terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.32.0"
    }
    couchbase-capella = {
      source = "couchbasecloud/couchbase-capella"
    }
  }
  backend "s3" {
  }
  required_version = ">= 1.5"
}
