# SPDX-License-Identifier: GPL-3.0-or-later
#
# @summary Manages BIND configuration
#
# @api private
#
class bind::config {
  assert_private()
  require bind::configchecks

  if $bind::options {
    $merged_options = $bind::default_options + $bind::options
  } else {
    $merged_options = $bind::default_options
  }

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
    content      => epp("${module_name}/etc/bind/named.conf.epp",
                        {'options' => $merged_options}),
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
    mode         => '0640',
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
        validate_cmd => "/usr/sbin/named-checkzone -k fail -m fail -M fail -n fail -r fail -S fail '${names['zonename']}' %",
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

  if $bind::zones {
    $bind::zones.each |$zone| {
      if $zone['type'] in ['primary', 'master', 'redirect'] and $zone['resource-records'] {
        $soa_index = $zone['resource-records'].index |$rr| { $rr['type'].upcase == 'SOA' }

        if $soa_index {
          $soa_ttl = $zone.dig('resource-records', $soa_index, 'ttl')
          $soa_data = $zone.dig('resource-records', $soa_index, 'data')
          $soa_fields = $soa_data.split(/\s+/)
          $mname = $soa_fields[0]
          $rname = $soa_fields[1]
          $serial = Integer($soa_fields[2])
          $refresh = $soa_fields[3]
          $retry = $soa_fields[4]
          $expire = $soa_fields[5]
          $negative_caching_ttl = $soa_fields[6]

          $ns_index = $zone['resource-records'].index |$rr| {
            $rr['type'].upcase == 'AAAA' and $rr['name'] == $mname
          }

          $ns_legacy_index = $zone['resource-records'].index |$rr| {
            $rr['type'].upcase == 'A' and $rr['name'] == $mname
          }

          if $ns_index {
            $ns_address = $zone.dig('resource-records', $ns_index, 'data')
          } else {
            $ns_address = undef
          }

          if $ns_legacy_index {
            $ns_legacy_address = $zone.dig('resource-records', $ns_legacy_index, 'data')
          } else {
            $ns_legacy_address = undef
          }
        } else {
          $soa_ttl =
          $mname =
          $rname =
          $serial =
          $refresh =
          $retry =
          $expire =
          $negative_caching_ttl =
          $ns_address =
          $ns_legacy_address =
          undef
        }

        file { extlib::path_join([$merged_options['directory'], "db.${zone['name']}"]):
          ensure       => file,
          owner        => $bind::service_user,
          replace      => false,
          content      => epp(
            "${module_name}/db.empty.epp",
            {
              'ttl'                  => $zone['ttl'],
              'soa_ttl'              => $soa_ttl,
              'mname'                => $mname,
              'rname'                => $rname,
              'serial'               => $serial,
              'refresh'              => $refresh,
              'retry'                => $retry,
              'expire'               => $expire,
              'negative_caching_ttl' => $negative_caching_ttl,
              'ns_address'           => $ns_address,
              'ns_legacy_address'    => $ns_legacy_address,
            },
          ),
          validate_cmd => "/usr/sbin/named-checkzone -k fail -m fail -M fail -n fail -r fail -S fail '${zone['name']}' %",
        }
      }
    }
  }
}
