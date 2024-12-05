# : CodeDeploy Application

resource "aws_codedeploy_app" "app" {
  name = "MyApp"

}
# CodeDeploy Deployment Group
resource "aws_codedeploy_deployment_group" "cdeploy_group" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "cdeploy-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "web_server"
    }
  }
}
# CodeDeploy Deployment Group