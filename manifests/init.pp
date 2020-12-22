# @summary Manage the BIND name server and DNS zones
#
# This class manages the BIND domain name server and DNS zones.
#
# @example
#   include bind
#
# @param config_dir
#   Directory for BIND configuration files.
#
# @param manage_package
#   Whether to have this module manage the BIND package.
#
# @param manage_service
#   Whether to have this module manage the BIND service.
#
# @param package_backport
#   Whether to install the BIND package from Debian backports.
#
# @param package_name
#   The name of the BIND package.
#
# @param package_ensure
#   The `ensure` parameter for the BIND package.
#
# @param service_enable
#   The `enable` parameter for the BIND service.
#
# @param service_ensure
#   The `ensure` parameter for the BIND service.
#
# @param service_name
#   The name of the BIND service.
#
class bind (
  Stdlib::Absolutepath $config_dir,
  Boolean $manage_package,
  Boolean $manage_service,
  Boolean $package_backport,
  String[1] $package_name,
  String[1] $package_ensure,
  Variant[Boolean, String[1]] $service_enable,
  Stdlib::Ensure::Service $service_ensure,
  String[1] $service_name,
) {
  if $package_backport {
    include apt::backports
  }

  if $package_backport and $facts['os']['release']['major'] == '10' {
    $_service_name = 'named'
  } else {
    $_service_name = $service_name
  }

  $package_install_options = $package_backport ? {
      true    => ['--target-release', "${facts['os']['distro']['codename']}-backports"],
      default => undef,
  }

  if $manage_package {
    package { $package_name:
      ensure          => $package_ensure,
      install_options => $package_install_options,
    }
  }

  $service_require = $manage_package ? {
    true    => Package[$package_name],
    default => undef,
  }

  if $manage_service and $package_ensure != 'absent' {
    service { $_service_name:
      ensure  => $service_ensure,
      enable  => $service_enable,
      require => $service_require,
    }
  } elsif $manage_service and $package_ensure == 'absent' {
    service { $_service_name:
      ensure => stopped,
      enable => false,
    }
  }

  file { extlib::path_join([$config_dir, 'named.conf.options']):
    ensure  => file,
    content => epp("${module_name}/${config_dir}/named.conf.options"),
  }
}
