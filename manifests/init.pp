# SPDX-License-Identifier: AGPL-3.0-or-later

# @summary Manages the BIND domain name server and DNS zones
#
# @example Caching nameserver with default configuration
#   include bind
#
# @param authoritative
#   Whether to enable features needed for authoritative server operation.
#
# @param config_dir
#   Directory for BIND configuration files.
#
# @param default_options
#   Default BIND
#   [options](https://bind9.readthedocs.io/en/latest/reference.html#options-statement-grammar) loaded
#   from Hiera data in this module's `data` directory. Merged with, and overridden by, the `options`
#   parameter. You'll generally want to use the `options` parameter and leave `default_options`
#   alone.
#
# @param default_zones
#   Whether to include the default zones in the BIND configuration.
#
# @param dev_packages
#   List of BIND development packages.
#
# @param doc_packages
#   List of BIND documentation packages.
#
# @param utils_packages
#   List of BIND utilities packages.
#
# @param includes
#   Additional configuration files to include in the BIND configuration using the
#   [include](https://bind9.readthedocs.io/en/latest/reference.html#include-statement-grammar)
#   statement.
#
# @param dev_packages_ensure
#   The `ensure` value for the BIND development packages (libraries and header files).
#
# @param doc_packages_ensure
#   The `ensure` value for the BIND documentation packages.
#
# @param utils_packages_ensure
#   The `ensure` value for the BIND utilities packages.
#
# @param logging
#   Configuration of the [logging
#   statement](https://bind9.readthedocs.io/en/latest/reference.html#logging-statement-grammar).
#
# @param keys
#   Hash for creating Bind::Key resources.
#
# @param options
#   Configuration of the [options
#   statement](https://bind9.readthedocs.io/en/latest/reference.html#options-statement-grammar).
#   Merged with, and overrides, the `default_options` parameter.
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
# @param root_hint_zone
#   Whether to include the root zone "." in the BIND configuration with [type
#   `hint`](https://bind9.readthedocs.io/en/latest/reference.html#zone-types).
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
# @param service_group
#   The primary group of `$service_user`. Used for directory permissions.
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
# @param zones
#   Hash for creating Bind::Zone resources.
#
# @param zone_default_expire
#   The default SOA expire time, set per a [RIPE
#   recommendation](https://www.ripe.net/publications/docs/ripe-203) (same as with all of the default
#   time values). Can be overridden by individual zones by providing a SOA record in the zone's hash
#   of the `$zones` parameter. Reference: [RFC
#   1035](https://tools.ietf.org/html/rfc1035#section-3.3.13)
#
# @param zone_default_mname
#   The default SOA MNAME. That is, the domain name of the primary name server for the zone. Can be
#   overridden by individual zones by providing a SOA record in the zone's hash of the `$zones`
#   parameter. Reference: [RFC 1035](https://tools.ietf.org/html/rfc1035#section-3.3.13)
#
# @param zone_default_negative_caching_ttl
#   The default negative caching TTL, the last field of the SOA record. Can be overridden by
#   individual zones by providing a SOA record in the zone's hash of the `$zones` parameter.
#   Reference: [RFC 2308](https://tools.ietf.org/html/rfc2308)
#
# @param zone_default_refresh
#   The default SOA refresh time. Can be overridden by individual zones by providing a SOA record in
#   the zone's hash of the `$zones` parameter. Reference: [RFC
#   1035](https://tools.ietf.org/html/rfc1035#section-3.3.13)
#
# @param zone_default_retry
#   The default SOA retry time. Can be overridden by individual zones by providing a SOA record in
#   the zone's hash of the `$zones` parameter. Reference: [RFC
#   1035](https://tools.ietf.org/html/rfc1035#section-3.3.13)
#
# @param zone_default_rname
#   The default SOA RNAME. That is, the domain name-formatted email address of the person responsible
#   for the zone. Can be overridden by individual zones by providing a SOA record in the zone's hash
#   of the `$zones` parameter. Reference: [RFC
#   1035](https://tools.ietf.org/html/rfc1035#section-3.3.13)
#
# @param zone_default_serial
#   The default initial serial number for the zone. Can be overridden by individual zones by
#   providing a SOA record in the zone's hash of the `$zones` parameter.
#
# @param zone_default_ttl
#   The default zone-wide TTL. This value is used in the zone's `$TTL` directive at the start of the
#   zone. Individual zones can override this default with the `ttl` key in their configuration hashes
#   in the `$zones` parameter. Also, individual resource records can override this value with the
#   `ttl` key in their hashes. Reference: [RFC 2308](https://tools.ietf.org/html/rfc2308#section-4)
#
class bind (
  Boolean $authoritative = false,
  Stdlib::Absolutepath $config_dir = '/etc/bind',
  Bind::Options $default_options = {
    'directory' => '/var/cache/bind',
  },
  Boolean $default_zones = true,
  Array[String[1]] $dev_packages = ['bind9-dev'],
  Array[String[1]] $doc_packages = ['bind9-doc'],
  Optional[Variant[Array[Bind::Include], Bind::Include]] $includes = undef,
  Optional[String[1]] $dev_packages_ensure = undef,
  Optional[String[1]] $doc_packages_ensure = undef,
  String[1] $utils_packages_ensure = 'installed',
  Hash $keys = {},
  Optional[Bind::Logging] $logging = undef,
  Optional[Bind::Options] $options = undef,
  Boolean $package_backport = false,
  String[1] $package_ensure = installed,
  Boolean $package_manage = true,
  String[1] $package_name = 'bind9',
  String[1] $resolvconf_package_name = 'openresolv',
  Boolean $resolvconf_service_enable = false,
  Boolean $root_hint_zone = true,
  Stdlib::Absolutepath $service_config_file = extlib::path_join([$config_dir, 'named.conf']),
  Variant[Boolean, String[1]] $service_enable = true,
  Stdlib::Ensure::Service $service_ensure = running,
  Boolean $service_manage = true,
  String[1] $service_name = 'named',
  Optional[String[1]] $service_options = undef,
  String[1] $service_user = 'bind',
  String[1] $service_group = $service_user,
  Array[String[1]] $utils_packages = ['bind9-dnsutils'],
  Hash $zones = {},
  String[1] $zone_default_expire = '1000h',
  String[1] $zone_default_mname = $facts['networking']['hostname'],
  String[1] $zone_default_negative_caching_ttl = '1h',
  String[1] $zone_default_refresh = '24h',
  String[1] $zone_default_retry = '2h',
  String[1] $zone_default_rname = 'hostmaster',
  Integer[0] $zone_default_serial = 1,
  String[1] $zone_default_ttl = '2d',
) {
  contain bind::install
  contain bind::config
  contain bind::service

  Class['bind::install']
  -> Class['bind::config']
  ~> Class['bind::service']
}
