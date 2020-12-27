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

  tidy { $bind::config_dir:
    matches => 'named.conf.*',
    recurse => true,
  }
}
