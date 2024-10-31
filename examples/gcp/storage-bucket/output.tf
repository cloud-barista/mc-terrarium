output "StorageBucketInfo" {
  description = "Information about the created GCP Cloud Storage bucket, including details for accessing and managing the bucket."
  value = {
    bucket_name          = google_storage_bucket.tofu_example_bucket.name
    location             = google_storage_bucket.tofu_example_bucket.location
    url                  = google_storage_bucket.tofu_example_bucket.url
    storage_class        = google_storage_bucket.tofu_example_bucket.storage_class
    self_link            = google_storage_bucket.tofu_example_bucket.self_link
    project              = google_storage_bucket.tofu_example_bucket.project
    uniform_access_level = google_storage_bucket.tofu_example_bucket.uniform_bucket_level_access
  }
}
