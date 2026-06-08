variable "aws_region" {
  description = "AWS region used for the lab."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Prefix used for naming AWS resources."
  type        = string
  default     = "w8-day-a-webapp"
}

variable "instance_type" {
  description = "EC2 instance type for the public web server."
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class for MySQL."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name for the RDS instance."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the RDS instance."
  type        = string
  default     = "adminuser"
}

variable "admin_ingress_cidrs" {
  description = "CIDR blocks allowed to SSH into the EC2 instance."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_cidr" {
  description = "CIDR block for the lab VPC."
  type        = string
  default     = "10.50.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for two public subnets."
  type        = list(string)
  default     = ["10.50.1.0/24", "10.50.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for two private subnets."
  type        = list(string)
  default     = ["10.50.11.0/24", "10.50.12.0/24"]
}

variable "tags" {
  description = "Extra tags applied to AWS resources."
  type        = map(string)
  default     = {}
}
