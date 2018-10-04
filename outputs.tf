# Output security groups
output "security-groups" {
  value = ["${aws_security_group.cfshield-sgAuto.*.id}"]
}
