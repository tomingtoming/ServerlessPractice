variable "stage" {
  default = "stg"
}

provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-codepipeline-backend"
    key    = "terraform-codepipeline-backend"
    region = "ap-northeast-1"
  }
}

resource "aws_codepipeline" "codepipeline" {
  name     = "${var.stage}_codepipeline"
  role_arn = "${aws_iam_role.codepipeline.arn}"

  artifact_store {
    location = "${aws_s3_bucket.artifact_store.bucket}"
    type     = "S3"

    encryption_key {
      id   = "${data.aws_kms_alias.encryption_key.arn}"
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name     = "Source"
      category = "Source"
      owner    = "ThirdParty"
      provider = "GitHub"
      version  = "1"

      configuration {
        Owner  = "tomingtoming"
        Repo   = "ServerlessPractice"
        Branch = "master"
      }

      output_artifacts = [
        "ServerlessPractice",
      ]
    }
  }

  stage {
    name = "Build"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"

      input_artifacts = [
        "ServerlessPractice",
      ]

      version = "1"

      configuration {
        ProjectName = "${var.stage}-serverless-build-deploy"
      }
    }
  }
}

resource "aws_iam_role" "codepipeline" {
  name = "${var.stage}_codepipeline"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "${var.stage}_codepipeline"
  role = "${aws_iam_role.codepipeline.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_s3_bucket" "artifact_store" {
  bucket = "${var.stage}-artifact-store"
  acl    = "private"
}

data "aws_kms_alias" "encryption_key" {
  name = "alias/${var.stage}_encryption_key"
}

resource "aws_codebuild_project" "codebuild" {
  name          = "${var.stage}_codebuild"
  description   = "Serverless deploy (stage: ${var.stage})"
  build_timeout = "5"
  service_role  = "${aws_iam_role.codepipeline.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = "${aws_s3_bucket.artifact_store.bucket}"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/golang:1.10"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}
