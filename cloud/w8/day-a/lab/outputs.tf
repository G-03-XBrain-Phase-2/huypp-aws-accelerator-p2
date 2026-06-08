output "vpc_id" {
  description = "VPC created for the lab."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the web tier."
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by the database tier."
  value       = module.vpc.private_subnets
}

output "web_public_ip" {
  description = "Public IP of the EC2 web server."
  value       = aws_instance.web.public_ip
}

output "web_url" {
  description = "HTTP URL of the EC2 web server."
  value       = "http://${aws_instance.web.public_ip}"
}

output "healthcheck_url" {
  description = "Health endpoint exposed by the demo application."
  value       = "http://${aws_instance.web.public_ip}/health"
}

output "rds_endpoint" {
  description = "Endpoint of the private MySQL database."
  value       = aws_db_instance.app.address
}

output "db_master_secret_arn" {
  description = "Secrets Manager ARN generated for the RDS master password."
  value       = aws_db_instance.app.master_user_secret[0].secret_arn
}

output "static_assets_bucket_name" {
  description = "S3 bucket used for static assets."
  value       = aws_s3_bucket.static_assets.bucket
}
