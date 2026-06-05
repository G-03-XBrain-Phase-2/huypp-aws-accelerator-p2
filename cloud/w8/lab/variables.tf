variable "aws_region" {
  description = "AWS region used for the lab."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Prefix used for naming AWS resources."
  type        = string
  default     = "w8-kind-lab"
}

variable "instance_type" {
  description = "EC2 instance type for the single-node Kubernetes host."
  type        = string
  default     = "t3.small"
}

variable "app_port" {
  description = "Container port served by the demo application."
  type        = number
  default     = 80
}

variable "node_port" {
  description = "Static NodePort exposed from kind to the EC2 host."
  type        = number
  default     = 30080
}

variable "host_port" {
  description = "EC2 host port mapped into the kind control-plane container."
  type        = number
  default     = 8080
}

variable "ssh_ingress_cidrs" {
  description = "CIDR blocks allowed to SSH into the EC2 host. Keep open only for lab use."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Extra tags applied to AWS resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the lab VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two public subnet CIDRs used by the ALB and EC2 host."
  type        = list(string)
  default     = ["10.42.1.0/24", "10.42.2.0/24"]
}
