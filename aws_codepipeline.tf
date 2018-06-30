variable "stage" {
  default = "stg"
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_caller_identity" "self" { }

terraform {
  backend "s3" {
    bucket = "serverless-practice-backend"
    key    = "serverless-practice-backend"
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
        Owner                = "tomingtoming"
        Repo                 = "serverless-practice"
        Branch               = "master"
        PollForSourceChanges = "false"
      }

      output_artifacts = [
        "serverless-practice-source",
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
        "serverless-practice-source",
      ]

      output_artifacts = [
        "serverless-practice-build",
      ]

      version = "1"

      configuration {
        ProjectName = "${var.stage}-serverless-build"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"

      input_artifacts = [
        "serverless-practice-build",
      ]

      version = "1"

      configuration {
        ProjectName = "${var.stage}-serverless-deploy"
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

resource "aws_iam_role" "codebuild" {
  name = "${var.stage}_codebuild"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
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

resource "aws_iam_role_policy" "codebuild" {
  name = "${var.stage}_codebuild"
  role = "${aws_iam_role.codebuild.id}"

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
  bucket = "${var.stage}-artifact-store-${data.aws_caller_identity.self.account_id}"
  acl    = "private"
}

data "aws_kms_alias" "encryption_key" {
  name = "alias/${var.stage}_encryption_key"
}

resource "aws_codebuild_project" "serverless-build" {
  name          = "${var.stage}-serverless-build"
  description   = "Serverless build (stage: ${var.stage})"
  build_timeout = "5"
  service_role  = "${aws_iam_role.codebuild.arn}"

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

    environment_variable {
      "name"  = "stage"
      "value" = "${var.stage}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-build.yml"
  }
}

resource "aws_codebuild_project" "serverless-deploy" {
  name          = "${var.stage}-serverless-deploy"
  description   = "Serverless deploy (stage: ${var.stage})"
  build_timeout = "5"
  service_role  = "${aws_iam_role.codebuild.arn}"

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = "${aws_s3_bucket.artifact_store.bucket}"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/nodejs:8.11.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      "name"  = "stage"
      "value" = "${var.stage}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec-deploy.yml"
  }
}
