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

  file { $bind::service_config_file:
    ensure  => file,
    content => epp("${module_name}/etc/bind/named.conf.epp"),
  }

  file { extlib::path_join([$bind::config_dir, 'bind.keys']):
    ensure  => file,
    content => file("${module_name}/etc/bind/bind.keys"),
  }

  if $bind::default_zones {
    ['db.0', 'db.127', 'db.255', 'db.empty', 'db.local'].each |$file| {
      file { extlib::path_join([$bind::config_dir, $file]):
        ensure  => file,
        content => file("${module_name}/etc/bind/${file}"),
      }
    }
  }

  tidy { $bind::config_dir:
    matches => 'named.conf.*',
    recurse => true,
  }
}
