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


resource "template_file" "webserver-userdata" {
  count = "${var.webserver-count}"
  template = "${file("templates/userdata.tpl")}"
  vars {
    hostname = "${format("webserver-%02d.demo.maxserv.com", count.index+1)}"
    master_ip = "${var.master_ip}"
  }
}

resource "aws_instance" "webserver" {
  count = "${var.webserver-count}"
  ami = "ami-33734044"
  instance_type = "t2.micro"
  vpc_security_group_ids = [
    "${aws_security_group.demo-webservers.id}"
  ]
  user_data = "${element(template_file.webserver-userdata.*.rendered, count.index)}"
  subnet_id = "${element(aws_subnet.demo-private.*.id, count.index%2)}"
  source_dest_check = true
  key_name = "${aws_key_pair.demo-administrator.key_name}"
  monitoring = true
  root_block_device  {
    volume_type = "gp2"
    volume_size = "10"
    delete_on_termination = true
  }
  # We require the NAT instances to be up & running in order to download the required packages
  # and receive puppet provisioning from the external puppet master, so make sure they're up:
  depends_on = ["aws_instance.demo-nat"]
  tags {
    Name = "${format("webserver-%02d.demo.maxserv.com", count.index+1)}"
    resource-group = "${var.resource_group}"
  }
}

output "webserver-ips" {
  value = "${join(",", aws_instance.webserver.*.dns)}"
}