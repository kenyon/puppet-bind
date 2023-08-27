# SPDX-License-Identifier: AGPL-3.0-or-later
#
# @summary Manages BIND configuration
#
# @api private
#
class bind::config {
  assert_private()

  if $bind::options {
    $merged_options = $bind::default_options + $bind::options
  } else {
    $merged_options = $bind::default_options
  }

  file { extlib::path_join(['/etc', 'default', bind::service_name()]):
    ensure  => absent,
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

  concat { $bind::service_config_file:
    validate_cmd => '/usr/sbin/named-checkconf %',
  }

  concat::fragment { 'named.conf base':
    target  => $bind::service_config_file,
    content => epp("${module_name}/etc/bind/named.conf.epp",
      {
        'options' => $merged_options,
      }
    ),
    order   => '01',
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
    mode         => '0640',
    validate_cmd => '/usr/sbin/named-checkconf %',
  }

  $default_zone_filenames_to_names = {
    'db.0' => '0.in-addr.arpa',
    'db.127' => '127.in-addr.arpa',
    'db.255' => '255.in-addr.arpa',
    'db.local' => 'localhost',
  }

  if $bind::default_zones {
    $default_zone_filenames_to_names.each |$filename, $name| {
      file { extlib::path_join([$bind::config_dir, $filename]):
        ensure       => file,
        content      => file("${module_name}/etc/bind/${filename}"),
        validate_cmd => "/usr/sbin/named-checkzone -k fail -m fail -M fail -n fail -r fail -S fail '${name}' %",
      }
    }
  }

  # BIND's working directory.
  file { $merged_options['directory']:
    ensure => directory,
    owner  => root,
    group  => $bind::service_group,
    mode   => '0775',
  }

  $bind::zones.each |$zone_name, $zone| {
    bind::zone { $zone_name:
      * => $zone,
    }
  }

  $bind::keys.each |$k, $v| {
    bind::key { $k:
      * => $v,
    }
  }
}
