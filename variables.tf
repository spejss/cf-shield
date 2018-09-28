variable "create_role" {}

variable "myvpc_id" {
  # default = "${data.aws_vpc.default.id}"
}

variable "region_name" {}

variable "func_name" {
  default = "cfshield-Agent-Coulson"
}
