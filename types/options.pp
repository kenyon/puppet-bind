# SPDX-License-Identifier: AGPL-3.0-or-later

# @summary Type definition for BIND's `options` statement
#
# Reference: https://bind9.readthedocs.io/en/latest/reference.html#options-statement-grammar
#
type Bind::Options = Struct[{
  Optional['allow-transfer'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address, Stdlib::Compat::String]],
  Optional['allow-update'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address, Stdlib::Compat::String]],
  Optional['allow-query'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
  Optional['also-notify'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address, Stdlib::Compat::String]],
  Optional['auto-dnssec'] => Enum['allow', 'maintain', 'off'],
  Optional['directory'] => Stdlib::Absolutepath,
  Optional['dnssec-enable'] => Variant[Boolean, Stdlib::Yes_no],
  Optional['dnssec-validation'] => Stdlib::Compat::String,
  Optional['inline-signing'] => Variant[Boolean, Stdlib::Yes_no],
  Optional['key-directory'] => String[1],
  Optional['listen-on'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address, Stdlib::Compat::String]],
  Optional['listen-on-v6'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address, Stdlib::Compat::String]],
  Optional['recursion'] => Variant[Boolean, Stdlib::Yes_no],
  Optional['serial-update-method'] => Enum['date', 'increment', 'unixtime'],
  Optional['tkey-gssapi-keytab'] => Stdlib::Absolutepath,
  Optional['version'] => Stdlib::Compat::String,
  Optional['zone-statistics'] => Variant[Boolean, Stdlib::Yes_no, Enum['full', 'terse', 'none']],
}]
