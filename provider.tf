# Provider SNS topic 
provider "aws" {
  alias = "sns"
  region = "us-east-1"
}

provider "aws" {
  region = "eu-central-1"
}

