# SPDX-License-Identifier: AGPL-3.0-or-later
#
# @summary Manages BIND installation
#
# @api private
#
class bind::install {
  assert_private()

  ensure_packages(
    [
      'g++',
      'make',
    ],
    {
      ensure => installed,
      before => Package['dnsruby'],
    },
  )

  # workaround for https://github.com/rvm/rvm/issues/4975
  # The dnsruby build fails with the Ruby 2.7.1 build included with Puppet 7.1.0 if /usr/bin/mkdir
  # is missing.
  # FIXME: remove this when Puppet's Ruby is fixed.
  file { '/usr/bin/mkdir':
    ensure => link,
    target => '/bin/mkdir',
    before => Package['dnsruby'],
  }

  ensure_packages(
    'dnsruby',
    {
      ensure   => installed,
      provider => puppet_gem,
    },
  )

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

  if $bind::install_dev_packages {
    if $bind::package_backport {
      ensure_packages('bind9-dev')
    } else {
      ensure_packages($bind::dev_packages)
    }
  }

  if $bind::install_doc_packages {
    ensure_packages($bind::doc_packages)
  }

  if $bind::install_utils_packages {
    if $bind::package_backport {
      ensure_packages('bind9-dnsutils')
    } else {
      ensure_packages($bind::utils_packages)
    }
  }
}
