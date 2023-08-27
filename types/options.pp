# SPDX-License-Identifier: AGPL-3.0-or-later

# @summary Type definition for BIND's `options` statement
#
# Reference: https://bind9.readthedocs.io/en/latest/reference.html#options-statement-grammar
#
type Bind::Options = Struct[{
  Optional['allow-transfer'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
  Optional['allow-update'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
  Optional['allow_recursion'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
  Optional['allow-query'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
  Optional['also-notify'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
  Optional['auto-dnssec'] => Enum['allow', 'maintain', 'off'],
  Optional['directory'] => Stdlib::Absolutepath,
  Optional['inline-signing'] => Variant[Boolean, Stdlib::Yes_no],
  Optional['key-directory'] => String[1],
  Optional['serial-update-method'] => Enum['date', 'increment', 'unixtime'],
  Optional['zone-statistics'] => Variant[Boolean, Stdlib::Yes_no, Enum['full', 'terse', 'none']],
  Optional['forward'] => Enum['first', 'only'],
  Optional['forwarders'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
}]
