/* Copyright 2016 Remco Overdijk - MaxServ B.V.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

resource "aws_elb" "demo-maxserv-com" {
  name = "demo-maxserv-com"
  # Although the webservers live in private subnets, the ELB's have to be in a PUBLIC subnet to be connected.
  subnets = ["${aws_subnet.demo-public.*.id}"]
  security_groups = ["${aws_security_group.demo-elb.id}"]
  instances = ["${aws_instance.webserver.*.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:80"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = false
  connection_draining_timeout = 400

  tags {
    Name = "demo-maxserv-com"
  }
}

output "elb-demo" {
  value = "${aws_elb.demo-maxserv-com.dns_name}"
}