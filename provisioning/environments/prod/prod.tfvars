env    = "prod"
region = "eu-west-2"

collection_ttl_configuration = {
  messages      = 7776000
  sessions_info = 7776000
}
couchbase_clusters_params = {
  company-cluster = {
    couchbase_server_version = "7.6.3"
    availability_type        = "single"
    support = {
      plan     = "developer pro"
      timezone = "GMT"
    }
    cloud_provider = {
      type   = "aws"
      region = "eu-west-2"
      cidr   = "10.4.2.0/24"
    }
    service_groups = [
      {
        node = {
          compute = {
            cpu = 4
            ram = 16
          }
          disk = {
            iops    = 3000
            storage = 50
            type    = "gp3"
          }
        }
        num_of_nodes = 3
        services = [
          "data",
          "index",
          "query",
          "search",
        ]
      }
    ]
  }
}