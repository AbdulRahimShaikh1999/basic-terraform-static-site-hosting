variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "s3-static-website"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}
