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

  file { extlib::path_join([$bind::config_dir, 'named.conf.options']):
    ensure  => file,
    content => epp("${module_name}/${bind::config_dir}/named.conf.options.epp"),
  }
}
