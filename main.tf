# IAM ROLE
resource "aws_iam_role" "iamRoleForLambda" {
  count = "${var.create_role == "True" ? 1 : 0 }"
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

resource "aws_security_group" "cfshield-sgAuto" {
  name        = "cfshield-sgAuto-${count.index}"
  description = "cfshield-sgAuto auto update by lambda"
  count       = 2
  vpc_id      = "${var.myvpc_id == "False" ? local.defvpc : var.myvpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Lambda
resource "aws_lambda_function" "cfshield-lambdaFunc" {
  filename      = "${path.module}/lambda.zip"
  function_name = "${var.func_name}"
  role          = "${aws_iam_role.iamRoleForLambda.arn}"

  handler          = "lambda.lambda_handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "python2.7"
  timeout          = "15"

  environment {
    variables = {
      sg_shield_1   = "${aws_security_group.cfshield-sgAuto.0.id}"
      sg_shield_2   = "${aws_security_group.cfshield-sgAuto.1.id}"
      REGION_NAME   = "${var.region_name}"
    }
  }
}

# subscribe sns topic ipspace
resource "aws_sns_topic_subscription" "cfshield-ipSpaceChanged_Provider" {
  provider  = "aws.sns"
  topic_arn = "${var.sns-topic}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.cfshield-lambdaFunc.arn}"
}