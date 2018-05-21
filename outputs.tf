output "bigiqLicenseManager" {
  value = "${var.bigiqLicenseManager}"
}

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}

output "vpc-id" {
  value = "${aws_vpc.terraform-vpc.id}"
}

output "vpc-public-a" {
  value = "${aws_subnet.public-a.cidr_block}"
}

output "vpc-public-a-id" {
  value = "${aws_subnet.public-a.id}"
}

output "vpc-private-a" {
  value = "${aws_subnet.private-a.cidr_block}"
}

output "vpc-private-a-id" {
  value = "${aws_subnet.private-a.id}"
}

output "vpc-public-b" {
  value = "${aws_subnet.public-a.cidr_block}"
}

output "vpc-public-b-id" {
  value = "${aws_subnet.public-a.id}"
}

output "vpc-private-b" {
  value = "${aws_subnet.private-a.cidr_block}"
}

output "vpc-private-b-id" {
  value = "${aws_subnet.private-a.id}"
}

output "sshKey" {
  value = "${var.aws_keypair}"
}

output "bigipExternalSecurityGroup" {
  value = "${aws_security_group.elb.id}"
}

output "bigipManagementSecurityGroup" {
  value = "${aws_security_group.f5_management.id}"
}

output "managementSubnetAz1" {
  value = "${aws_subnet.f5-management-a.id}"
}

output "managementSubnetAz2" {
  value = "${aws_subnet.f5-management-b.id}"
}

output "restrictedSrcAddress" {
  value = "0.0.0.0/0"
}

output ssl_certificate_id {
  value = "${aws_iam_server_certificate.elb_cert.arn}"
}

output "**aws_alias**" {
  value = "${var.aws_alias}"
}
