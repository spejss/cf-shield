# CloudFront Shield

Protect your origin by adding security groups with CloudFront IPs always updated by lambda.

## How it works

This module create the follow resources:

* Create policies and roles to run lambda with right permissions. 
* Create security groups to fill with CloudFront IPs as a necessary.
* Create lambda function to get all CloudFront IPs and fill security groups.
* Subscribe SNS topic called [AmazonIpSpaceChanged](https://aws.amazon.com/blogs/aws/aws-ip-ranges-json/) in Virginia region and select lambda as an endpoint target.
* Output filled security groups ready to attach in your resources.
* Slack messagens optionally

## Patameters

* func_name [ Optional ] <br>
  values = [a-Z]

* create_role [ Optional ] <br>
  values = true or false <br>
  if you alredy roles and policies to run lambda!

* myvpc_id [ Optional ]    
  values = vpc-id <br> 
  Only if you have custom VPC instead of default VPC. 
* region_name [ Mandatory ] <br>
  value = AZ code  

* slack_url
  value = incoming-webhook url <br>
  See [slack documentation](https://api.slack.com/incoming-webhooks) to create one.

* PAY ATTENTION WARNING <br>
  **Mandatory** if you **aren't** using US East (N. Virginia) - **us-east-1** <br>
  Additional provider for subscribe SNS topic. This topic only exists on us-east-1. Check this [Post](https://aws.amazon.com/blogs/aws/aws-ip-ranges-json/) to understand. <br>
  You must create a provider to subscribe SNS Topic in us-east-1. See the example.

## Examples

### Using South America (Sao Paulo) - sa-east-1
```
# Provider Example
AWS provider documentation -> https://www.terraform.io/docs/providers/aws/ <br>

# Extra provider
provider "aws" {
    alias   = "sns"
    region  = "us-east-1"
    profile = "${var.aws_profile}"
}

# How to pass provider in module
module "hidemyoriginass" {
    source = "git::https://my-git-url/terraform-modules/cf-shield.git"
    region_name = "sa-east-1"
    providers = {
        aws.sns = "aws.sns"
    }  
} 
```

### Using US East (N. Virginia) - us-east-1

```
module "hidemyoriginass" {
  source = "git::https://my-git-url/terraform-modules/cf-shield.git"
  create_role = "true" 
  region_name = "us-east-1"
}
```

### Using South America (Sao Paulo) - sa-east-1 + slack msg
```
provider "aws" {
    alias   = "sns"
    region  = "us-east-1"
    profile = "${var.aws_profile}"
}

module "hidemyoriginass" {
    source = "git::https://my-git-url/terraform-modules/cf-shield.git"
    func_name   = "LetMeChooseForYou"
    create_role = "true" 
    myvpc_id    = "vpc-0pt10n4l" 
    region_name = "sa-east-1" 

  # Mandatory if you aren't using us-east-1 
  providers = {
    aws.sns = "aws.sns"
  }
  
  slack_url     = "https://hooks.slack.com/services/T00ASFASMM/MADSLKJFAS9/jgals9a90ue0020"
  slack_channel = "devops-haters"
}
```

### Complete example
```
# Provider
provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

provider "aws" {
  alias   = "sns"
  region  = "sa-east-1"
  profile = "${var.aws_profile}"
}

# Variable
variable "aws_profile" {
  default = "myprofile"
}

variable "aws_region" {
  default = "sa-east-1"
}

# Data
data "aws_vpc" "selected" {
  default = true
}

data "aws_subnet_ids" "selected" {
  vpc_id = "${data.aws_vpc.selected.id}"
}

data "aws_subnet" "selected" {
  count = "${length(data.aws_subnet_ids.selected.ids)}"
  id    = "${data.aws_subnet_ids.selected.ids[count.index]}"
}

# Module
module "hidemyoriginass" {
  source        = "git::https://my-git-url/terraform-modules/cf-shield.git"
  create_role   = "true"
  region_name   = "${var.aws_region}"
  slack_url     = "https://hooks.slack.com/services/TTTTTTTT/AAAAAAAA/dfsV0eNASDdfaFDw2FSA"
  slack_channel = "devops-haters"

  providers = {
    aws.sns = "aws.sns"
  }
}

# Load Balance
resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${module.hidemyoriginass.security-groups}"]

  subnets = ["${data.aws_subnet.selected.*.id}"]
}

# Output
output "Module security-group output" {
  value = "${module.hidemyoriginass.security-groups}"
}
```