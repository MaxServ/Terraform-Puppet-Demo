/* Copyright 2016 Remco Overdijk - MaxServ B.V.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

# The main VPC contains all resources
resource "aws_vpc" "demo-vpc" {
  cidr_block = "10.99.0.0/16"
  tags {
    Name = "demo-vpc"
    resource-group = "${var.resource_group}"
  }
}
# The subnets contain the actual resources

# We have 2 public subnets that only contain NAT instances, one for each AZ we're in.
resource "aws_subnet" "demo-public" {
  count = 2
  vpc_id = "${aws_vpc.demo-vpc.id}"
  availability_zone = "${lookup(var.zones, count.index)}"
  cidr_block = "${lookup(var.public_blocks, count.index)}"
  tags {
    Name = "${format("demo-public-%s", lookup(var.zones, count.index))}"
    resource-group = "${var.resource_group}"
  }
}

# Then there's also two private subnets that contain the real resources, shielded from the internet.
resource "aws_subnet" "demo-private" {
  count = 2
  vpc_id = "${aws_vpc.demo-vpc.id}"
  availability_zone = "${lookup(var.zones, count.index)}"
  cidr_block = "${lookup(var.private_blocks, count.index)}"
  tags {
    Name = "${format("demo-private-%s", lookup(var.zones, count.index))}"
    resource-group = "${var.resource_group}"
  }
}

# The internet gateway connects the public subnets to the internet
resource "aws_internet_gateway" "demo-vpc-igw" {
  vpc_id = "${aws_vpc.demo-vpc.id}"

  tags {
    Name = "demo-vpc-igw"
    resource-group = "${var.resource_group}"
  }
}

# The S3 endpoint connects S3 to the VPC for use in routing tables
resource "aws_vpc_endpoint" "private-s3" {
  vpc_id = "${aws_vpc.demo-vpc.id}"
  service_name = "com.amazonaws.eu-west-1.s3"
  route_table_ids = [
    "${aws_route_table.demo-vpc-rt-public-subnets.id}",
    "${aws_route_table.demo-vpc-rt-private-a.id}",
    "${aws_route_table.demo-vpc-rt-private-b.id}"
  ]
}


# The route tables are what make a VPC public or private, and control what traffic goes where.

# The public subnets have the same routing table, which connects them to the internet using an igw on 0.0.0.0/0
resource "aws_route_table" "demo-vpc-rt-public-subnets" {
  vpc_id = "${aws_vpc.demo-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.demo-vpc-igw.id}"
  }

  tags {
    Name = "demo-vpc-rt-public-subnets"
    resource-group = "${var.resource_group}"
  }
}

# The private subnets each have their own routing tables, which NAT's them behind a NAT instance in their
# respective AZ public subnet.
resource "aws_route_table" "demo-vpc-rt-private-a" {
  vpc_id = "${aws_vpc.demo-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.demo-nat.0.id}"
  }

  tags {
    Name = "demo-vpc-rt-private-a"
    resource-group = "${var.resource_group}"
  }
}
resource "aws_route_table" "demo-vpc-rt-private-b" {
  vpc_id = "${aws_vpc.demo-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${aws_instance.demo-nat.1.id}"
  }

  tags {
    Name = "demo-vpc-rt-private-b"
    resource-group = "${var.resource_group}"
  }
}

# This connects the route tables to their subnets
resource "aws_route_table_association" "public-a" {
  subnet_id = "${aws_subnet.demo-public.0.id}"
  route_table_id = "${aws_route_table.demo-vpc-rt-public-subnets.id}"
}
resource "aws_route_table_association" "public-b" {
  subnet_id = "${aws_subnet.demo-public.1.id}"
  route_table_id = "${aws_route_table.demo-vpc-rt-public-subnets.id}"
}
resource "aws_route_table_association" "private-a" {
  subnet_id = "${aws_subnet.demo-private.0.id}"
  route_table_id = "${aws_route_table.demo-vpc-rt-private-a.id}"
}
resource "aws_route_table_association" "private-b" {
  subnet_id = "${aws_subnet.demo-private.1.id}"
  route_table_id = "${aws_route_table.demo-vpc-rt-private-b.id}"
}

# The DHCP options set overrides default AWS/EC2 options
resource "aws_vpc_dhcp_options" "demo-maxserv-com" {
  domain_name = "demo.maxserv.com"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags {
    Name = "demo.maxserv.com"
    resource-group = "${var.resource_group}"
  }
}
resource "aws_vpc_dhcp_options_association" "demo-maxserv-com" {
  vpc_id = "${aws_vpc.demo-vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.demo-maxserv-com.id}"
}
