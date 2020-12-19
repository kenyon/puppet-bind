# @summary Manage the BIND name server and DNS zones
#
# This class manages the BIND name server and DNS zones.
#
# @example
#   include bind
class bind (
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
}
