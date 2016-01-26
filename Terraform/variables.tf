/* Copyright 2016 Remco Overdijk - MaxServ B.V.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#See: https://www.terraform.io/intro/getting-started/variables.html

variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "eu-west-1"
}

variable "resource_group" {
  default = "terraform-puppet-demo"
}
variable "zones" {
  default = {
    "0" = "eu-west-1a"
    "1" = "eu-west-1b"
  }
}

variable "public_blocks" {
  default = {
    "0" = "10.99.11.0/24"
    "1" = "10.99.22.0/24"
  }
}

variable "private_blocks" {
  default = {
    "0" = "10.99.33.0/24"
    "1" = "10.99.44.0/24"
  }
}

variable "public_key" {
  description = "Used in keypairs.tf to load an external public key, included by Env Var for example."
  # See: https://www.terraform.io/docs/configuration/variables.html for more info on Env Vars.
}
