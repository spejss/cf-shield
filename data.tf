data "aws_vpc" "default" {
  default = true
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "cfshield-iamPolicyDocument" {
  statement {
    actions = [
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeNetworkAcls",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
    ]

    resources = [
      "arn:aws:ec2:${var.region_name}:${data.aws_caller_identity.current.account_id}:security-group/*",
    ]

    #"arn:aws:ec2:${var.region_name}:${data.aws_caller_identity.current.account_id}:security-group/${aws_security_group.cfshield-sgAuto2.id}",
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}
