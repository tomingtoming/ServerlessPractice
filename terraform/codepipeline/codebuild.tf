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
    location = "${var.artifact_store_bucket}"
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
    buildspec = "serverless/buildspec-build.yml"
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
    location = "${var.artifact_store_bucket}"
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
    buildspec = "serverless/buildspec-deploy.yml"
  }
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
