provider "aws" {
  region = var.region
}

provider "couchbase-capella" {
  authentication_token = var.couchbase_capella_token
}