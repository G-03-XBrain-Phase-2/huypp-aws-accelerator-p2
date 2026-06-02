terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "tf-series-state-20260602071528361100000001"
    key          = "app/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
resource "aws_s3_bucket" "test" {
  bucket_prefix = "tf-series-state-"
  force_destroy = true # chỉ để dọn dẹp phòng lab; KHÔNG bật tính năng này trên môi trường production
}
resource "aws_s3_bucket" "app" {
  bucket_prefix = "tf-series-state-"
  force_destroy = true # chỉ để dọn dẹp phòng lab; KHÔNG bật tính năng này trên môi trường production
}
