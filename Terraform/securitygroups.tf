/* Copyright 2016 Remco Overdijk - MaxServ B.V.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#See: http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_NAT_Instance.html#NATSG
resource "aws_security_group" "NATSG" {
  name = "NATSG"
  vpc_id = "${aws_vpc.demo-vpc.id}"
  description = "Allows NAT traffic to the internet"

  # SSH IN - This allows SSH from the internet. DON'T do this in production, because it defies the reason we're using NAT,
  # which is to shield the setup from the internet. Usually you would connect a VPN to the VPC and allow SSH from there.
  # ** FOR DEMONSTRATION PURPOSES ONLY **
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP IN
  ingress {
    security_groups = [
      "${aws_security_group.demo-webservers.id}",
    ]
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }
  # HTTPS IN
  ingress {
    security_groups = [
      "${aws_security_group.demo-webservers.id}",
    ]
    from_port = 443
    to_port = 443
    protocol = "tcp"
  }
 # PUPPET IN
  ingress {
    security_groups = [
      "${aws_security_group.demo-webservers.id}",
    ]
    from_port = 8140
    to_port = 8140
    protocol = "tcp"
  }
  # SALT/ZEROMQ IN
  ingress {
    security_groups = [
      "${aws_security_group.demo-webservers.id}",
    ]
    from_port = 4505
    to_port = 4506
    protocol = "tcp"
  }

  # HTTP OUT
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTPS OUT
  egress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 # PUPPET OUT
  egress {
    from_port = 8140
    to_port = 8140
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 # SALT/ZEROMQ OUT
  egress {
    from_port = 4505
    to_port = 4506
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "NATSG"
    resource-group = "${var.resource_group}"
  }
}

resource "aws_security_group" "demo-webservers" {
  name = "demo-webservers"
  vpc_id = "${aws_vpc.demo-vpc.id}"
  description = "Allows traffic to webservers"

  # SSH IN - This allows SSH from the NAT boxes (used as a jumpnode).
  # DON'T do this in production, because it defies the reason we're using NAT,
  # which is to shield the setup from the internet. Usually you would connect a VPN to the VPC and allow SSH from there.
  # ** FOR DEMONSTRATION PURPOSES ONLY **
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.99.0.0/16"]
  }

 ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.demo-elb.id}"
    ]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.demo-elb.id}"
    ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "demo-webservers"
    resource-group = "${var.resource_group}"
  }
}

resource "aws_security_group" "demo-elb" {
  name = "demo-elb"
  vpc_id = "${aws_vpc.demo-vpc.id}"
  description = "Allow traffic to load balancers"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "demo-elb"
    resource-group = "${var.resource_group}"
  }
}
