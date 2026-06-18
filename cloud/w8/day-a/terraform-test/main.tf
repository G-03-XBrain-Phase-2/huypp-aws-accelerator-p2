terraform {
  required_version = ">= 1.15"  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
variable "secret_value" {
  type      = string
  sensitive = true
}

resource "aws_secretsmanager_secret" "wo" {
  name = "bai8-secret-wo"
}

# Write-only: giá trị KHÔNG bị ghi vào state
resource "aws_secretsmanager_secret_version" "wo" {
  secret_id                = aws_secretsmanager_secret.wo.id
  secret_string_wo         = var.secret_value
  secret_string_wo_version = 1
}