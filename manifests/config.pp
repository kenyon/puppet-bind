# SPDX-License-Identifier: GPL-3.0-or-later
#
# @summary Manage BIND configuration
#
# @api private
#
class bind::config {
  assert_private()

  file { extlib::path_join(['/etc', 'default', bind::service_name()]):
    ensure  => file,
    content => epp("${module_name}/etc/default/named.epp"),
  }

  file { $bind::config_dir:
    ensure  => directory,
    owner   => root,
    group   => $bind::service_group,
    mode    => '2755',
    force   => true,
    purge   => true,
    recurse => true,
  }

  file { $bind::service_config_file:
    ensure       => file,
    content      => epp("${module_name}/etc/bind/named.conf.epp"),
    validate_cmd => '/usr/sbin/named-checkconf %',
  }

  file { extlib::path_join([$bind::config_dir, 'bind.keys']):
    ensure       => file,
    content      => epp("${module_name}/etc/bind/bind.keys.epp"),
    validate_cmd => '/usr/sbin/named-checkconf %',
  }

  exec { '/usr/sbin/rndc-confgen -a':
    creates => extlib::path_join([$bind::config_dir, 'rndc.key']),
  }

  file { extlib::path_join([$bind::config_dir, 'rndc.key']):
    ensure       => file,
    owner        => root,
    group        => $bind::service_group,
    mode         => '0600',
    validate_cmd => '/usr/sbin/named-checkconf %',
  }

  $default_zone_names = [
    {
      'filename' => 'db.0',
      'zonename' => '0.in-addr.arpa',
    },
    {
      'filename' => 'db.127',
      'zonename' => '127.in-addr.arpa',
    },
    {
      'filename' => 'db.255',
      'zonename' => '255.in-addr.arpa',
    },
    {
      'filename' => 'db.local',
      'zonename' => 'localhost',
    },
  ]

  if $bind::default_zones {
    $default_zone_names.each |$names| {
      file { extlib::path_join([$bind::config_dir, $names['filename']]):
        ensure       => file,
        content      => file("${module_name}/etc/bind/${names['filename']}"),
        validate_cmd => "/usr/sbin/named-checkzone ${names['zonename']} %",
      }
    }
  }

  # BIND's working directory.
  file { $bind::options['directory']:
    ensure => directory,
    owner  => root,
    group  => $bind::service_group,
    mode   => '0775',
  }
}
