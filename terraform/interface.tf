variable "region" {
  default = "ap-northeast-1"
}

variable "stage" {
  default = "staging"
}

data "aws_caller_identity" "self" {}
