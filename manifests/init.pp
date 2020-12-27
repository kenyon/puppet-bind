# @summary Manage the BIND domain name server and DNS zones
#
# @example
#   include bind
#
# @param config_dir
#   Directory for BIND configuration files.
#
# @param includes
#   Additional configuration files to include in the BIND configuration using the
#   [include](https://bind9.readthedocs.io/en/latest/reference.html#include-statement-grammar)
#   statement.
#
# @param options
#   Configuration of the [options
#   statement](https://bind9.readthedocs.io/en/latest/reference.html#options-statement-grammar). At
#   least the `directory` option must be specified. You need to provide the quotation marks for
#   `quoted_string` types.
#
# @param package_manage
#   Whether to have this module manage the BIND package.
#
# @param service_manage
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
# @param resolvconf_package_name
#   The name of the resolvconf package to use if `resolvconf_service_enable` is `true`.
#
# @param resolvconf_service_enable
#   Whether to enable the named-resolvconf service so that localhost's BIND resolver is used in
#   `/etc/resolv.conf`.
#
# @param service_config_file
#   The path to the BIND config file.
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
# @param service_user
#   The user to run BIND as (for the `-u` command line option).
#
# @param service_options
#   [Command line
#   options](https://bind9.readthedocs.io/en/latest/manpages.html#named-internet-domain-name-server)
#   for the BIND service.
#
class bind (
  Stdlib::Absolutepath $config_dir,
  Hash $options,
  Boolean $package_backport,
  String[1] $package_name,
  String[1] $resolvconf_package_name,
  Boolean $resolvconf_service_enable,
  String[1] $service_name,
  String[1] $service_user,
  Optional[Variant[Stdlib::Absolutepath, Array[Stdlib::Absolutepath]]] $includes = undef,
  String[1] $package_ensure = installed,
  Boolean $package_manage = true,
  Stdlib::Absolutepath $service_config_file = extlib::path_join([$config_dir, 'named.conf']),
  Variant[Boolean, String[1]] $service_enable = true,
  Stdlib::Ensure::Service $service_ensure = running,
  Boolean $service_manage = true,
  Optional[String[1]] $service_options = undef,
) {
  contain bind::install
  contain bind::config
  contain bind::service

  Class['bind::install']
  -> Class['bind::config']
  ~> Class['bind::service']
}
