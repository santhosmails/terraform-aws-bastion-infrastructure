# AWS Secure Bastion Host Infrastructure

## Overview
Enterprise-grade AWS infrastructure implementing a secure bastion host pattern using Infrastructure as Code (IaC) with Terraform. This setup enables secure access to private resources while following AWS Well-Architected Framework principles and DevOps best practices.

![Architecture Diagram](docs/architecture.png)

## Features

### Security & Compliance
- ✅ IMDSv2 requirement enforced on all instances
- ✅ Network segmentation with public/private subnets
- ✅ IP-restricted SSH access (CIDR-based)
- ✅ Security groups with least privilege access
- ✅ Encrypted EBS volumes
- ✅ SSH key-based authentication

### Infrastructure as Code
- ✅ Declarative infrastructure using Terraform
- ✅ Remote state management with S3
- ✅ Modular and reusable design
- ✅ Automated resource tagging
- ✅ Version-controlled infrastructure

## Architecture

### Network Design
- VPC with dedicated CIDR (10.176.0.0/16)
- Public subnet for bastion (10.176.10.0/28)
- Private subnet for workloads (10.176.20.0/24)
- Security group isolation

### Compute Resources
- Bastion: Ubuntu 22.04 LTS
- Private instances: Amazon Linux 2
- Instance type: t2.micro (cost-optimized)
- IMDSv2 enabled for enhanced security

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.5.0
- SSH key pair for instance access
- S3 bucket for Terraform state

## Deployment Guide

1. **Clone and Configure**

```bash
git clone <repository-url>
cd terraform-aws-bastion-infrastructure
```

2. **Configure Variables**
```hcl
prefix              = "bastion"
allowed_ssh_cidr    = "YOUR_IP/32"
region              = "us-east-1"
environment         = "staging"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"
```

3. **Deploy Infrastructure**
```bash
terraform init
terraform plan
terraform apply
```

4. **Access Instances**
```bash
Connect to bastion
ssh ubuntu@<bastion-public-ip>

Connect to private instances via bastion
ssh -A -J ubuntu@<bastion-public-ip> ec2-user@<private-instance-ip>
```


## Security Considerations

### Network Security
- Bastion host in public subnet
- Application servers in private subnet
- Restricted SSH access by CIDR
- Security group rules:
  - Inbound SSH only from specified CIDR
  - Private instances accessible only via bastion

### Instance Security
- IMDSv2 requirement
- EBS encryption
- SSH key authentication



### State Management
Configure remote state storage with S3:
```hcl
terraform {
  backend "s3" {
    bucket  = "YOUR_S3_BUCKET_NAME"
    key     = "bastion/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
```

### Tagging Strategy
Use consistent tagging to organize resources:
```hcl
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "infrastructure-team"
  }
}
```

This setup ensures your bastion host infrastructure is secure, modular, and ready for scalable deployment on AWS.

## Future Improvements

### High Availability & Infrastructure
- ⭐ Convert bastion to Auto Scaling Group with Launch Template
- ⭐ Add Application Load Balancer for bastion access
- ⭐ Implement cross-AZ deployment for all resources
- ⭐ Add DynamoDB table for Terraform state locking