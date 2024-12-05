

#  CodePipeline Configuration
resource "aws_codepipeline" "pipeline" {
  name     = "MyPipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.new_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarConnection"
      version          = "2"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "deemoney14"
        Repo       = "codepipeline-codedeploy"
        Branch     = "main"
        ConnectionArn = var.codestar_connect
      }
    }
  }


  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["source_output"]
      version         = "2"
      configuration = {
        ApplicationName     = aws_codedeploy_app.app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.cdeploy_group.deployment_group_name

      }
    }
  }

}