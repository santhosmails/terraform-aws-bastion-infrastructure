terraform {
  backend "s3" {
    bucket  = "YOUR_S3_BUCKET"
    key     = "bastion/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}