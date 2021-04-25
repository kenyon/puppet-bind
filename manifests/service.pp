# SPDX-License-Identifier: AGPL-3.0-or-later
#
# @summary Manages BIND service
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
    systemd::dropin_file { "${bind::service_name()}.conf":
      unit    => "${bind::service_name()}.service",
      content => epp("${module_name}/etc/systemd/system/named.service.d/named.conf.epp"),
    } ~> service { bind::service_name():
      ensure => $bind::service_ensure,
      enable => $bind::service_enable,
    }
  } elsif $bind::service_manage and $bind::package_ensure == 'absent' {
    systemd::dropin_file { "${bind::service_name()}.conf":
      ensure => absent,
      unit   => "${bind::service_name()}.service",
    }

    service { bind::service_name():
      ensure => stopped,
      enable => false,
    }
  }
}
