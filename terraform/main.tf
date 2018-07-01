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

resource "aws_s3_bucket" "artifact_store" {
  bucket = "artifact-store-${data.aws_caller_identity.self.account_id}"
  acl    = "private"
}

module "staging" {
  source                = "./codepipeline"
  stage                 = "staging"
  source_branch         = "develop"
  artifact_store_bucket = "${aws_s3_bucket.artifact_store.bucket}"
}

module "production" {
  source                = "./codepipeline"
  stage                 = "production"
  source_branch         = "master"
  artifact_store_bucket = "${aws_s3_bucket.artifact_store.bucket}"
}
