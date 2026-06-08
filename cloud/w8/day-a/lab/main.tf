provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = replace(lower(var.project_name), "_", "-")
  common_tags = merge({
    Project   = var.project_name
    ManagedBy = "terraform"
    Lab       = "w8-day-a"
  }, var.tags)
}

resource "random_id" "suffix" {
  byte_length = 2
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "web_app" {
  statement {
    sid = "ReadDbSecret"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [aws_db_instance.app.master_user_secret[0].secret_arn]
  }

  statement {
    sid = "ListAndReadAssetsBucket"

    actions = [
      "s3:ListBucket"
    ]

    resources = [aws_s3_bucket.static_assets.arn]
  }

  statement {
    sid = "ReadWriteAssetsObjects"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = ["${aws_s3_bucket.static_assets.arn}/*"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true
  enable_dns_support     = true

  public_subnet_tags = {
    Tier = "public"
  }

  private_subnet_tags = {
    Tier = "private"
  }

  tags = local.common_tags
}

resource "aws_security_group" "web" {
  name_prefix = "${local.name_prefix}-web-"
  description = "Allow HTTP from Internet and SSH from admin CIDRs"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from operators"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_ingress_cidrs
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web-sg"
  })
}

resource "aws_security_group" "db" {
  name_prefix = "${local.name_prefix}-db-"
  description = "Allow MySQL only from the web tier"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "MySQL from web tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-sg"
  })
}

resource "aws_iam_role" "web" {
  name               = "${local.name_prefix}-web-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_policy" "web_app" {
  name   = "${local.name_prefix}-web-app-policy"
  policy = data.aws_iam_policy_document.web_app.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "web_app" {
  role       = aws_iam_role.web.name
  policy_arn = aws_iam_policy.web_app.arn
}

resource "aws_iam_instance_profile" "web" {
  name = "${local.name_prefix}-web-profile"
  role = aws_iam_role.web.name

  tags = local.common_tags
}

resource "aws_s3_bucket" "static_assets" {
  bucket        = "${local.name_prefix}-assets-${random_id.suffix.hex}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-assets"
  })
}

resource "aws_s3_bucket_versioning" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket                  = aws_s3_bucket.static_assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_db_subnet_group" "app" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = module.vpc.private_subnets

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-subnets"
  })
}

resource "aws_db_instance" "app" {
  identifier                   = "${local.name_prefix}-mysql"
  allocated_storage            = 20
  max_allocated_storage        = 100
  storage_type                 = "gp3"
  engine                       = "mysql"
  engine_version               = "8.0"
  instance_class               = var.db_instance_class
  db_name                      = var.db_name
  username                     = var.db_username
  manage_master_user_password  = true
  db_subnet_group_name         = aws_db_subnet_group.app.name
  vpc_security_group_ids       = [aws_security_group.db.id]
  multi_az                     = false
  publicly_accessible          = false
  skip_final_snapshot          = true
  deletion_protection          = false
  backup_retention_period      = 0
  performance_insights_enabled = false

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-mysql"
  })
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.web.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.web.name
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    aws_region    = var.aws_region
    db_endpoint   = aws_db_instance.app.address
    db_name       = var.db_name
    db_user       = var.db_username
    db_secret_arn = aws_db_instance.app.master_user_secret[0].secret_arn
    s3_bucket     = aws_s3_bucket.static_assets.bucket
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web"
  })
}
