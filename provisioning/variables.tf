variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "couchbase_clusters_params" {
  default = {}
}

variable "couchbase_default_cluster_id" {
  default = ""
}

variable "couchbase_default_project_id" {
  default = ""
}

variable "collection_ttl_configuration" {
  default = {}
}

variable "couchbase_capella_token" {
  description = "APIv4 token to access to CouchBase Capella"
  type        = string
  sensitive   = true
}