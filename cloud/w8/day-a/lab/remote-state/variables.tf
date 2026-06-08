variable "aws_region" {
  description = "AWS region used for the remote state resources."
  type        = string
  default     = "ap-southeast-1"
}

variable "name_prefix" {
  description = "Prefix used for the state bucket and lock table."
  type        = string
  default     = "w8-day-a-tf-state"
}

variable "tags" {
  description = "Extra tags applied to backend resources."
  type        = map(string)
  default     = {}
}
