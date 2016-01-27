/* Copyright 2016 Remco Overdijk - MaxServ B.V.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class demo::apache {
  $apache = hiera_hash('apache')
  $apacheBase = $apache['base']
  $apacheConfDir = "${apacheBase}/conf.d"
  $errorPagesConfig = $apache['errorPagesConfig']

  include ::epel

  package { $apache['packages']:
    ensure  => latest,
    require => Class['::epel']
  }

  service { 'httpd':
    ensure     => running,
    name       => $apache['servicename'],
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [
      Package[$apache['servicename']],
    ],
  }
  exec { 'reload-httpd':
    command     => '/usr/sbin/apachectl graceful',
    refreshonly => true,
    require     => Service['httpd'],
  }

  exec { 'force-reload-httpd':
    command     => '/usr/sbin/apachectl restart',
    refreshonly => true,
    require     => Service['httpd'],
  }

  file { $apacheConfDir:
    ensure  => 'directory',
    owner   => 0,
    group   => 0,
    mode    => '0755',
    require => Package[$apache['servicename']],
  }
  
  file { "${apacheBase}/virtualhosts":
    ensure  => 'directory',
    owner   => 0,
    group   => 0,
    mode    => '0755',
    require => Package[$apache['servicename']],
  }

  file { "${apacheBase}/error":
    ensure  => 'directory',
    owner   => 0,
    group   => 0,
    mode    => '0755',
    require => Package[$apache['servicename']],
  }
  
  file { "${apacheBase}/conf/httpd.conf":
    owner   => 0,
    group   => 0,
    mode    => '0644',
    source  => $apache['httpdConfig'],
    require => [
      Package[$apache['servicename']]
    ],
    notify  => Exec["force-reload-${apache['servicename']}"]
  }

  file { "${apacheConfDir}/maxserv-errorpages.conf":
    owner   => 0,
    group   => 0,
    mode    => '0644',
    source  => $errorPagesConfig,
    require => [
      File[$apacheConfDir],
      File["${apacheBase}/error"]
    ],
    notify  => Exec["reload-${apache['servicename']}"]
  }

  file { "${apacheConfDir}/welcome.conf":
      ensure => 'absent'
  }

  $errorpages = hiera_hash('apache-errorpages')
  create_resources(errorpage, $errorpages, {ensure => 'present', require => Package[$apache['servicename']]})
  firewall { '300 apache ports IN' :
      ensure => 'present',
      chain  => 'INPUT',
      proto  => 'tcp',
      dport  => [80],
      action => 'accept',
  }
}
