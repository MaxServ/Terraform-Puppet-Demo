/* Copyright 2016 Remco Overdijk - MaxServ B.V.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#Provision two NAT instances; One for each Availability Zone.
resource "aws_instance" "demo-nat" {
  count = 2
  ami = "ami-6975eb1e"
  instance_type = "t2.micro"
  vpc_security_group_ids = [
    "${aws_security_group.NATSG.id}"
  ]
  subnet_id = "${element(aws_subnet.demo-public.*.id, count.index%2)}"

  # See: http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_NAT_Instance.html
  # NAT instances need the source_dest_check disabled or they won't route traffic for other EC2 instances.
  source_dest_check = false

  key_name = "${aws_key_pair.demo-administrator.key_name}"
  tags {
    Name = "${format("demo-nat-%02d.demo.maxserv.com", count.index+1)}"
    resource-group = "${var.resource_group}"
  }
}

#Assign an Elastic IP to the NAT instance
resource "aws_eip" "eip-nat-a01" {
  instance = "${aws_instance.demo-nat.0.id}"
  vpc = true
}

#See: https://www.terraform.io/intro/getting-started/outputs.html
output "nat-a01-ip" {
  value = "${aws_eip.eip-nat-a01.public_ip}"
}
resource "aws_eip" "eip-nat-b01" {
  instance = "${aws_instance.demo-nat.1.id}"
  vpc = true
}
output "nat-b01-ip" {
  value = "${aws_eip.eip-nat-b01.public_ip}"
}
