resource "aws_s3_bucket" "artifact_store" {
  bucket = "${var.stage}-artifact-store-${data.aws_caller_identity.self.account_id}"
  acl    = "private"
}

resource "aws_codepipeline" "codepipeline" {
  name     = "${var.stage}_codepipeline"
  role_arn = "${aws_iam_role.codepipeline.arn}"

  artifact_store {
    location = "${aws_s3_bucket.artifact_store.bucket}"
    type     = "S3"
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
        Branch               = "${var.stage == "prd" ? "master" : "develop"}"
        PollForSourceChanges = false
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
