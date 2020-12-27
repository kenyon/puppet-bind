# SPDX-License-Identifier: GPL-3.0-or-later
#
# @summary Manage BIND service
#
# @api private
#
class bind::service {
  assert_private()

  if $bind::resolvconf_service_enable {
    service { "${bind::service_name()}-resolvconf":
      ensure  => running,
      enable  => true,
      require => Package[$bind::resolvconf_package_name],
    }
  }

  if $bind::service_manage and $bind::package_ensure != 'absent' {
    service { bind::service_name():
      ensure => $bind::service_ensure,
      enable => $bind::service_enable,
    }
  } elsif $bind::service_manage and $bind::package_ensure == 'absent' {
    service { bind::service_name():
      ensure => stopped,
      enable => false,
    }
  }
}
