data "aws_vpc" "default" {
  default = true
}

# data "aws_subnet" "default" {
#   vpc_id            = "${data.aws_vpc.default.id}"
#   default_for_az    = true
#   availability_zone = "${var.availability_zone}"
# }


# data "aws_subnet_ids" "all" {
#   vpc_id = "${data.aws_vpc.vpc.id}"
# }


# #################### VPC ###########################
# data "aws_availability_zones" "available" {}
# data "aws_vpc" "projectvpc" {
#   tags {
#     project = "${var.vpc_tag}"
#   }
# }
# data "aws_subnet_ids" "projectsubnets" {
#   vpc_id = "${data.aws_vpc.projectvpc.id}"
# }
# #################### IAM ###########################
# data "aws_iam_role" "ecs_task" {
#   name = "${var.cluster_project}-ecs-task-${var.env}"
# }
# data "aws_iam_role" "ecs_service" {
#   name = "${var.cluster_project}-ecs-service-${var.env}"
# }
# ##################### ECS ###########################
# data "aws_ecs_cluster" "cluster" {
#   cluster_name = "${var.cluster_project}-${var.env}"
# }
# data "aws_ecr_repository" "repo" {
#   name = "${var.cluster_project}-${var.env}"
# }
# ###################### LB ##########################
# data "aws_lb" "lb" {
#   name = "${var.cluster_project}-prod-${var.internal ? "int" : "ext"}"
# }
# data "aws_lb_listener" "aws_lb_listener_http" {
#   load_balancer_arn = "${data.aws_lb.lb.arn}"
#   port              = "${var.http_port}"
# }
# data "aws_lb_listener" "aws_lb_listener_https" {
#   load_balancer_arn = "${data.aws_lb.lb.arn}"
#   port              = "${var.https_port}"
# }

