# Terraform & Puppet Demo

## Introduction
This demonstration will:

- **a:** Create and run a Puppet master in a Docker container that is able to provision the `demo::webserver` class to any node that connects with the `is_type:demo` fact. (Naïve autosigning is enabled).
- **b:** Create and destroy an AWS infrastructure using Terraform that includes 1 VPC, 4 subnets (2 public, 2 private, divided over two Availability Zones), 2 NAT/bastion instances, 4 EC2 webservers and 1 ELB.
- **c:** Automatically provision the 4 EC2 webservers terraformed in **b** using the Puppet master launched in **a**.
 
## Warnings
- This demonstration *will* generate an infrastructure on AWS that is not covered by the Free Tier. In other words: running this demonstration *will* cost you money.
- Running the code on an AWS account with existing infrastructure *may* result in conflicts with currently running parts, so I would advise to run this on an isolated AWS account.
- Both the provisioned AWS infrastructure and the Dockerized Puppetmaster have very generous firewall settings and very low (or no) security measures, because they were designed to be easily accessible. Running the code in this demonstration *will* make you vulnerable to attacks from the open internet, so I recommend against running the infrastructure for prolonged periods of time and/or combining it with existing production infrastructure.
- Although the source can be used as a basis for a production infrastructure, it requires mentioning that the source contained within this demonstration by no means resembles a production-ready infastructure. Important components like TLS, IAM roles/policies, CloudWatch alarms, Snapshots, Backups, network ACL's, strict Security Groups, Health Checks, VPN, SNS/SQS and monitoring were explicitly left out of the demonstration to simplify the process. Be smart and think about all aforementioned components before considering running any of this source in production and heed the warnings in the source.

## License & Disclaimer

Copyright 2016 Remco Overdijk - MaxServ B.V.

This Source Code Form is subject to the terms of the Mozilla Public License, v.2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/

Covered Software is provided under this License on an “as is” basis, without warranty of any kind, either expressed, implied, or statutory, including, without limitation, warranties that the Covered Software is free of defects, merchantable, fit for a particular purpose or non-infringing. The entire risk as to the quality and performance of the Covered Software is with You. Should any Covered Software prove defective in any respect, You (not any Contributor) assume the cost of any necessary servicing, repair, or correction. This disclaimer of warranty constitutes an essential part of this License. No use of  any Covered Software is authorized under this License except under this disclaimer.

## Requirements
- The key and secret for an AWS account with sufficient privileges to create and destroy EC2 and VPC resources.
- Docker must be installed on the workstation you use to run this code with. See: https://www.docker.com/products/docker-toolbox
- Terraform must be installed on the workstation you use to run this code with. See: https://www.terraform.io/downloads.html
- A public/private key pair for use with SSH. The public key will be uploaded to AWS to grant you SSH access to the bastion and webservers later.

## Instructions

1. Clone this repository

		git clone https://github.com/MaxServ/Terraform-Puppet-Demo.git

2. Create the file `Terraform/terraform.tfvars` that contains your AWS key & secret in this format:

		access_key = "AKXXXXXXXXXXXXXXXXX"
		secret_key = "YYYYYYYYYYYYYYYYYYYYYYYYYYYYYY"

3. Launch a publicly reachable `docker-machine` that will host the puppet master container. I chose to run it in AWS to stick with the theme. See https://docs.docker.com/machine/drivers/aws/ for more parameters and options for launching. I've created the `docker` security group using Terraform, because we need to open up `8140` to allow puppet traffic later:

	```
	resource "aws_security_group" "docker" {
  		name = "docker"
  		vpc_id = "${aws_vpc.YOUR-VPC.id}"
  		description = "Allows internet traffic to docker hosts"

  		ingress {
    		from_port = 22
    		to_port = 22
    		protocol = "tcp"
    		cidr_blocks = ["0.0.0.0/0"]
  		}
  		ingress {
    		from_port = 2376
    		to_port = 2376
    		protocol = "tcp"
    		cidr_blocks = ["0.0.0.0/0"]
  		}
  		ingress {
    		from_port = 8140
			to_port = 8140
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
    		Name = "docker"
  		}
	}
	```
	Then:

		docker-machine create --driver amazonec2 \
		--amazonec2-access-key $(cat ../Terraform/terraform.tfvars | sed -n 1p | cut -d\" -f2) \
		--amazonec2-secret-key $(cat ../Terraform/terraform.tfvars | sed -n 2p | cut -d\" -f2) \
		--amazonec2-vpc-id vpc-XXXXXXXX --amazonec2-region eu-west-1 --amazonec2-security-group docker \
		--amazonec2-subnet-id subnet-XXXXXXXX aws-docker01

4. Launch the puppet master container into your `docker-machine`:
		
		cd Puppet
		# Configure your shell to use the previously created docker-machine:
		eval $(docker-machine env aws-docker01)
		# Build the container on the host
		docker-compose build
		# Run it
		docker-compose up -d
		# To check if it's up & running, run this to tail the puppet master logs:
		docker-compose logs

5. Gather the information required for running Terraform. You need your SSH public key and the IP address of the `docker-machine` that holds your (running) puppet master container. Port `8140` will need to be open on the host. I chose to save my public key as `Terraform/certificates/pubkey.pem`.
		
		export TF_VAR_public_key="$(cat certificates/pubkey.pem)"
		export TF_VAR_master_ip=$(docker-machine ip aws-docker01) 		

6. Launch the infrastructure in AWS.

		cd Terraform
		# To see the changes Terraform intends to perform on your infra, run:
		terraform plan
		# If everything looks good, run it on AWS:
		terraform apply

7. Once terraform is done, check your AWS console to admire your brand new infrastructure. Terraform reported the IP's for both NAT/bastion instances and the DNS name for the ELB. Use `ssh ec2-user@<NAT-IP>` as a jump node to reach your webservers (Which are in a private subnet) and tail the logs there to see if `cloud-config` is doing what it's supposed to do. Use `docker-compose logs` to see if the webservers received their catalog from the master, and visit the ELB in your browser to see your infrastructure in action.

8. Once you're done playing around with the infrastructure you should clean up. Remove the container, docker-machine and AWS infrastructure:

		cd Puppet
		docker-compose stop
		docker-compose rm
		docker-machine rm aws-docker01
		cd Terraform
		terraform destroy