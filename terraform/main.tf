terraform {
  backend "s3" {
    bucket = "serverless-practice-backend"
    key    = "serverless-practice-backend"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  region = "${var.region}"
}
