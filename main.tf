###########################
# VPC and Network Resources
###########################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

###########################
# Subnet Resources
###########################

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet"
    Tier = "Public"
  })
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.region}a"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-subnet"
    Tier = "Private"
  })
}

###########################
# Route Tables
###########################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

###########################
# Security Groups
###########################

resource "aws_security_group" "bastion" {
  name        = "${local.name_prefix}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-bastion-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = var.allowed_ssh_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress" {
  security_group_id = aws_security_group.bastion.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "private_instances" {
  name        = "${local.name_prefix}-private-instances-sg"
  description = "Security group for private instances"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-instances-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "private_instances_ssh" {
  security_group_id = aws_security_group.private_instances.id
  cidr_ipv4         = var.public_subnet_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "private_instances_icmp" {
  security_group_id = aws_security_group.private_instances.id
  cidr_ipv4         = var.private_subnet_cidr
  ip_protocol       = "icmp"
  from_port         = -1 # -1 means all ICMP types
  to_port           = -1 # -1 means all ICMP codes
}

resource "aws_vpc_security_group_egress_rule" "private_instances_egress" {
  security_group_id = aws_security_group.private_instances.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

###########################
# SSH Key
###########################

resource "aws_key_pair" "main" {
  key_name   = "${local.name_prefix}-key"
  public_key = file(var.ssh_public_key_path)

  tags = local.common_tags
}

###########################
# EC2 Instances
###########################

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu_22.id
  instance_type = "t2.micro"

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.main.key_name

  root_block_device {
    volume_size = 8
    encrypted   = true
  }

  tags = merge(local.common_tags, {
    Name = upper("${var.prefix}-host")
  })

  metadata_options {
    http_tokens = "required" # IMDSv2
  }
}

resource "aws_instance" "database" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"

  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_instances.id]
  key_name               = aws_key_pair.main.key_name
  private_ip             = "10.176.20.10"

  root_block_device {
    volume_size = 8
    encrypted   = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-database"
  })

  metadata_options {
    http_tokens = "required" # IMDSv2
  }
}

resource "aws_instance" "backend" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"

  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_instances.id]
  key_name               = aws_key_pair.main.key_name
  private_ip             = "10.176.20.11"

  root_block_device {
    volume_size = 8
    encrypted   = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-backend"
  })

  metadata_options {
    http_tokens = "required" # IMDSv2
  }
}