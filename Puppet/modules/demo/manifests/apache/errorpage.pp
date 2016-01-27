/* Copyright 2016 Remco Overdijk - MaxServ B.V.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

define demo::apache::errorpage (
  $ensure = 'present',
  $title = false,
  $header = false,
  $message = false,
  $email = false
) {

  if !$name or $name == false  {
    fail('An error page should have a title.')
  }

  $apache = hiera_hash('apache', {})
  $apacheBase = $apache['base']
  $apacheName = $apache['servicename']
  file { "${apacheBase}/error/${name}.html":
    ensure  => $ensure,
    owner   => 0,
    group   => 0,
    mode    => '0644',
    content => template('demo/apache_errorpage.erb'),
    require => [
      File["${apacheBase}/error"]
    ],
    notify  => Exec["reload-${apache['servicename']}"]
  }
}
