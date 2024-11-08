
output "mongodbInfo" {
  description = "Information MongoDB instance"
  value = {
    service_name = ncloud_mongodb.mongodb.service_name
    instance_id  = ncloud_mongodb.mongodb.id
    cluster_type = ncloud_mongodb.mongodb.cluster_type_code
  }
}
