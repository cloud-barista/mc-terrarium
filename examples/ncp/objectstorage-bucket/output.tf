output "ObjectStorageInfo" {
  description = "Naver Cloud Platform Object Storage Bucket Information"
  value = {
    bucket_name   = ncloud_objectstorage_bucket.tofu_bucket.bucket_name
    creation_date = ncloud_objectstorage_bucket.tofu_bucket.creation_date
    bucket_id     = ncloud_objectstorage_bucket.tofu_bucket.id
  }
}
