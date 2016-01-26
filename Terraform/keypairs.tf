/* Copyright 2016 Remco Overdijk - MaxServ B.V.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

# Loads an external public key using the variable.
# See: https://www.terraform.io/docs/configuration/variables.html for loading external variables

resource "aws_key_pair" "demo-administrator" {
  key_name = "demo-administrator"
  public_key = "${var.public_key}"
}
