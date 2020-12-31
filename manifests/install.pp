# SPDX-License-Identifier: GPL-3.0-or-later
#
# @summary Manages BIND installation
#
# @api private
#
class bind::install {
  assert_private()

  if $bind::package_backport {
    require apt::backports
  }

  $package_install_options = $bind::package_backport ? {
    true    => ['--target-release', "${facts['os']['distro']['codename']}-backports"],
    default => undef,
  }

  if $bind::resolvconf_service_enable {
    ensure_packages($bind::resolvconf_package_name,
                    {before => Package[$bind::package_name]})
  }

  if $bind::package_manage {
    package { $bind::package_name:
      ensure          => $bind::package_ensure,
      install_options => $package_install_options,
    }
  }
}
