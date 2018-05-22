variable "aws_region" {}
variable "aws_profile" {}
variable "vpc_cidr" {}

variable "bucket_name" {}

data "aws_availability_zones" "available" {
}

variable "cidrs" {
  type = "map"
}

variable "lambda_runtime" {}

variable "instance_type" {}

variable "asg_max" {}
variable "asg_min" {}
variable "asg_capacity" {}
variable "asg_grace" {}

variable "db_engine" {
  default = "aurora-mysql"
}

variable "db_name" {}
variable "db_user" {}
variable "db_instance_class" {}
variable "db_password" {}
data "aws_caller_identity" "current" {}
variable "lambda_s3_bucket" {}
variable "lambda_zip_file_name" {}

variable "rest_api_name" {
  default = "web"
}

variable "deployment_stage" {
  default = "test"
}
