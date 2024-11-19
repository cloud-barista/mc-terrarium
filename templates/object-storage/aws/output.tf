output "object_storage_info" {
  description = "Information about AWS S3 bucket storage"
  value = {
    terrarium = {
      id = var.terrarium_id # "terrarium-01"
    }
    object_storage_detail = {
      # Basic Information
      storage_name = aws_s3_bucket.object_storage.bucket # "terrarium01-bucket"
      location     = aws_s3_bucket.object_storage.region # "ap-northeast-2"
      tags         = aws_s3_bucket.object_storage.tags   # { "Name" = "terrarium01-bucket" }

      # Access Configuration
      public_access_enabled = !aws_s3_bucket_public_access_block.object_storage_public_access.block_public_acls # false
      https_only            = true                                                                              # S3 always uses HTTPS
      primary_endpoint      = aws_s3_bucket.object_storage.bucket_domain_name                                   # "terrarium01-bucket.s3.amazonaws.com"

      provider_specific_detail = {
        provider             = "aws"                                                          # "aws"
        bucket_name          = aws_s3_bucket.object_storage.bucket                            # "terrarium01-bucket"
        bucket_arn           = aws_s3_bucket.object_storage.arn                               # "arn:aws:s3:::terrarium01-bucket"
        bucket_region        = aws_s3_bucket.object_storage.region                            # "ap-northeast-2"
        regional_domain_name = aws_s3_bucket.object_storage.bucket_regional_domain_name       # "terrarium01-bucket.s3.ap-northeast-2.amazonaws.com"
        versioning_enabled   = try(aws_s3_bucket.object_storage.versioning[0].enabled, false) # false

        public_access_config = {
          block_public_acls       = aws_s3_bucket_public_access_block.object_storage_public_access.block_public_acls       # true
          block_public_policy     = aws_s3_bucket_public_access_block.object_storage_public_access.block_public_policy     # true
          ignore_public_acls      = aws_s3_bucket_public_access_block.object_storage_public_access.ignore_public_acls      # true
          restrict_public_buckets = aws_s3_bucket_public_access_block.object_storage_public_access.restrict_public_buckets # true
        }
      }
    }
  }
}


# # For design
# output "object_storage_all" {
#   description = "All information"
#   value       = aws_s3_bucket.object_storage
#   sensitive   = true
# }

# output "aws_s3_bucket_public_access_block_all" {
#   description = "All information"
#   value       = aws_s3_bucket_public_access_block.object_storage_public_access
#   sensitive   = true
# }
