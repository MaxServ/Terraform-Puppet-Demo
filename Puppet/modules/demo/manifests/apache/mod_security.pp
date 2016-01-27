/* Copyright 2016 Remco Overdijk - MaxServ B.V.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class demo::apache::mod_security {

  $apache = hiera_hash('apache')
  $apacheBase = $apache['base']

  if $::osfamily == 'RedHat' {
    package { 'mod_security':
      ensure  => latest,
      require => Package['httpd'],
      notify  => Exec["force-reload-${apache['servicename']}"]
    }

    file { "${apacheBase}/modsecurity.d/serverheader.conf":
      owner   => 0,
      group   => 0,
      mode    => '0644',
      content => template('demo/mod_security-serverheader.erb'),
      require => Package['mod_security'],
      notify  => Exec["reload-${apache['servicename']}"]
    }

    file { '/var/lib/mod_security':
      ensure  => 'directory',
      owner   => 'apache',
      group   => 0,
      mode    => '0770',
      require => Package['mod_security'],
    }
  }
}
