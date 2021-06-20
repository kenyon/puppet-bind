# @summary A DNS zone
#
# @example Basic usage
#   bind::zone { 'example.com.': }
#
# @param zone_name The name of the zone.
#
# @param allow_transfer Which hosts are allowed to receive zone transfers from the server.
#   https://bind9.readthedocs.io/en/latest/reference.html#allow-transfer-access
#
# @param allow_update Which hosts are allowed to submit Dynamic DNS updates to the zone.
#
# @param also_notify list of IP addresses of name servers that are also sent NOTIFY messages
#   whenever a fresh copy of the zone is loaded, in addition to the servers listed in the zone’s NS
#   records.
#
# @param auto_dnssec The automatic DNSSEC key management mode.
#
# @param class DNS class. Defaults to 'IN', for Internet.
#   https://bind9.readthedocs.io/en/latest/reference.html#class
#
# @param file The zone's filename.
#
# @param forward This option is only meaningful if the zone has a forwarders list. The 'only' value
#   causes the lookup to fail after trying the forwarders and getting no answer, while 'first' allows
#   a normal lookup to be tried. https://bind9.readthedocs.io/en/latest/reference.html#forwarding
#
# @param forwarders Hosts to which queries are forwarded.
#   https://bind9.readthedocs.io/en/latest/reference.html#forwarding
#
# @param in_view Allows for referencing the zone in another view.
#
# @param inline_signing Allows BIND to automatically sign zones.
#
# @param key_directory The directory where the public and private DNSSEC key files should be found
#   when performing a dynamic update of secure zones, if different than the current working
#   directory.
#
# @param manage
#   Whether to manage the contents of this zone with Puppet. If false, only manages the configuration
#   of the zone in named.conf. If true, creates and manages the zone file and resource records of the
#   zone.
#
# @param masters Synonym for `primaries`.
#
# @param primaries Defines a named list of servers for inclusion in stub and secondary zones'
#   primaries or also-notify lists.
#
# @param purge Whether to purge unmanaged resource records from the zone.
#
# @param resource_records Hash for creating `resource_record` resources.
#
# @param serial_update_method Method for incrementing the zone's serial number.
#
# @param ttl The value for the `$TTL` directive, which sets the default resource record TTL for the
#   zone.
#
# @param type The zone type. https://bind9.readthedocs.io/en/latest/reference.html#zone-types
#
# @param update_policy The update-policy.
#   https://bind9.readthedocs.io/en/latest/reference.html#dynamic-update-policies
#
define bind::zone (
  Pattern[/\.$/] $zone_name = $title,
  Optional[Array[Variant[Stdlib::Host, Stdlib::IP::Address, Stdlib::Compat::String]]] $allow_transfer = undef,
  Optional[Array[Variant[Stdlib::Host, Stdlib::IP::Address, Stdlib::Compat::String]]] $allow_update = undef,
  Optional[Array[Variant[Stdlib::Host, Stdlib::IP::Address, Stdlib::Compat::String]]] $also_notify = undef,
  Optional[Enum['allow', 'maintain', 'off']] $auto_dnssec = undef,
  Optional[Enum['IN', 'HS', 'hesiod', 'CHAOS']] $class = undef,
  Optional[String[1]] $file = undef,
  Optional[Enum['first', 'only']] $forward = undef,
  Optional[Array[Stdlib::Host]] $forwarders = undef,
  Optional[String[1]] $in_view = undef,
  Optional[Variant[Boolean, Stdlib::Yes_no]] $inline_signing = undef,
  Optional[String[1]] $key_directory = undef,
  Boolean $manage = false,
  Optional[Array[Stdlib::Host]] $masters = undef,
  Optional[Array[Stdlib::Host]] $primaries = undef,
  Boolean $purge = false,
  Hash $resource_records = {},
  Optional[Enum['date', 'increment', 'unixtime']] $serial_update_method = undef,
  Optional[String[1]] $ttl = undef,
  Optional[Enum[
    'primary',
    'master',
    'secondary',
    'slave',
    'mirror',
    'hint',
    'stub',
    'static-stub',
    'forward',
    'redirect',
    'delegation-only',
  ]] $type = undef,
  Optional[Array[Bind::ZoneConfig::UpdatePolicy]] $update_policy = undef,
) {
  include bind

  unless $type or $in_view {
    fail("zone ${zone_name}: must specify either in-view or type")
  }

  concat::fragment { $zone_name:
    target  => $bind::service_config_file,
    content => epp("${module_name}/zone.conf.epp", {
      'zone_name'            => $zone_name,
      'allow_transfer'       => $allow_transfer,
      'allow_update'         => $allow_update,
      'also_notify'          => $also_notify,
      'auto_dnssec'          => $auto_dnssec,
      'class'                => $class,
      'file'                 => $file,
      'forward'              => $forward,
      'forwarders'           => $forwarders,
      'in_view'              => $in_view,
      'inline_signing'       => $inline_signing,
      'key_directory'        => $key_directory,
      'masters'              => $masters,
      'primaries'            => $primaries,
      'purge'                => $purge,
      'serial_update_method' => $serial_update_method,
      'ttl'                  => $ttl,
      'type'                 => $type,
      'update_policy'        => $update_policy,
    }),
  }

  if $type in ['primary', 'master', 'redirect'] and $manage {
    unless $allow_update or $update_policy {
      fail("zone ${zone_name}: must be updatable locally via allow-update or update-policy")
    }

    if length($resource_records.filter |$rr| { $rr[1]['type'] and $rr[1]['type'].upcase == 'SOA' }) > 1 {
      fail('only one SOA record allowed per zone')
    }

    $soa_key = $resource_records.index |$rr| { $rr['type'] and $rr['type'].upcase == 'SOA' }

    if $soa_key {
      $soa_ttl = $resource_records.dig($soa_key, 'ttl')
      $soa_data = $resource_records.dig($soa_key, 'data')
      $soa_fields = $soa_data.split(/\s+/)
      $mname = $soa_fields[0]
      $rname = $soa_fields[1]
      $serial = Integer($soa_fields[2])
      $refresh = $soa_fields[3]
      $retry = $soa_fields[4]
      $expire = $soa_fields[5]
      $negative_caching_ttl = $soa_fields[6]

      $ns_key = $resource_records.index |$rr| {
        $rr['type'].upcase == 'AAAA' and $rr['record'] == $mname
      }

      $ns_legacy_key = $resource_records.index |$rr| {
        $rr['type'].upcase == 'A' and $rr['record'] == $mname
      }

      if $ns_key {
        $ns_address = $resource_records.dig($ns_key, 'data')
      } else {
        $ns_address = undef
      }

      if $ns_legacy_key {
        $ns_legacy_address = $resource_records.dig($ns_legacy_key, 'data')
      } else {
        $ns_legacy_address = undef
      }
    } else {
      $soa_ttl =
      $mname =
      $rname =
      $serial =
      $refresh =
      $retry =
      $expire =
      $negative_caching_ttl =
      $ns_address =
      $ns_legacy_address =
      undef
    }

    file { extlib::path_join([$bind::config::merged_options['directory'], "db.${zone_name}"]):
      ensure       => file,
      owner        => $bind::service_user,
      replace      => false,
      content      => epp(
        "${module_name}/db.empty.epp",
        {
          'ttl'                  => $ttl,
          'soa_ttl'              => $soa_ttl,
          'mname'                => $mname,
          'rname'                => $rname,
          'serial'               => $serial,
          'refresh'              => $refresh,
          'retry'                => $retry,
          'expire'               => $expire,
          'negative_caching_ttl' => $negative_caching_ttl,
          'ns_address'           => $ns_address,
          'ns_legacy_address'    => $ns_legacy_address,
        },
      ),
      validate_cmd => "/usr/sbin/named-checkzone -k fail -m fail -M fail -n fail -r fail -S fail '${zone_name}' %",
    }

    $resource_records.each |$rrname, $attribs| {
      resource_record { $rrname:
        zone => $zone_name,
        *    => $attribs,
      }
    }
  }
}
