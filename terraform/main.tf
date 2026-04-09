# Main Terraform configuration - Uses modular approach

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  secret_key = var.aws_secret_key
  access_key = var.aws_access_key
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  bucket_name  = var.bucket_name
  project_name = var.project_name
  environment  = var.environment
}

# CloudFront Module
module "cloudfront" {
  source = "./modules/cloudfront"

  bucket_domain_name          = module.s3.bucket_regional_domain_name
  bucket_arn                  = module.s3.bucket_arn
  project_name                = var.project_name
  environment                 = var.environment
  origin_access_identity_path = "/cloudfront/ABCDEFG1234567" # Placeholder
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name                = var.project_name
  environment                 = var.environment
  s3_bucket_arn               = module.s3.bucket_arn
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
}
