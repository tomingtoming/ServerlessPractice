variable "region" {
  default     = "ap-northeast-1"
}

variable "stage" {
  default = "stg"
}

data "aws_caller_identity" "self" {}
