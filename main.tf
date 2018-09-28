# Create:
# Lambda function 
# 2 SGs 

# IAM ROLE
resource "aws_iam_role" "iamRoleForLambda" {
  count = "${var.create_role == "true" ? 1 : 0 }"
  name  = "iamRoleForLambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

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
      "arn:aws:ec2:*:*:security-group/${aws_security_group.cfshield-sgAuto1.id}",
      "arn:aws:ec2:*:*:security-group/${aws_security_group.cfshield-sgAuto2.id}",
    ]
  }
}

resource "aws_iam_policy" "cfshield-iamPolicy" {
  name        = "cfshield-iamPolicy"
  description = "Lambda policy for update cf ips"
  policy      = "${data.aws_iam_policy_document.cfshield-iamPolicyDocument.json}"
  path        = "/"
}

resource "aws_iam_role_policy_attachment" "cfshield-rolePolicyAttach" {
  role       = "${aws_iam_role.iamRoleForLambda.name}"
  policy_arn = "${aws_iam_policy.cfshield-iamPolicy.arn}"
}

resource "aws_security_group" "cfshield-sgAuto1" {
  name        = "cfshield-sgAuto1"
  description = "cfshield-sgAuto1 auto update by lambda"

  vpc_id = "${var.myvpc_id}"

  #vpc_id = "${var.myvpc_id? var.myvpc_id : data.aws_vpc.default.id }"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "cfshield-sgAuto2" {
  name        = "cfshield-sgAuto2"
  description = "cfshield-sgAuto2 auto update by lambda"

  vpc_id = "${var.myvpc_id}"

  # vpc_id = "${var.myvpc_id == "" ? data.aws_vpc.default.id : ""  }"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

# Create Lambda
resource "aws_lambda_function" "cfshield-lambdaFunc" {
  filename      = "${data.archive_file.lambda_zip.output_path}"
  function_name = "${var.func_name}"
  role          = "${aws_iam_role.iamRoleForLambda.arn}"

  handler          = "lambda.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "python2.7"
  timeout          = "15"

  environment {
    variables = {
      sg_shield_1 = "${aws_security_group.cfshield-sgAuto1.id}"
      sg_shield_2 = "${aws_security_group.cfshield-sgAuto2.id}"
      REGION_NAME = "${var.region_name}"
    }
  }
}

# subscribe sns topic ipspace
# slack things
# Create Cloudwatch Events / Rules 
# Attach SGs to CF or LB

