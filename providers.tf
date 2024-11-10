terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.73.0"
    }
  }
  required_version = ">= 1.5.0, < 2.0.0"
}

provider "aws" {
  region = var.region
  # default_tags in the AWS provider block is a feature that automatically applies a set of tags to all resources created by that provider
  default_tags {
    tags = local.common_tags
  }
}
