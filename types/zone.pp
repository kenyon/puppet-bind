# SPDX-License-Identifier: GPL-3.0-or-later

# @summary Type definition for BIND's `zone` statement
#
# Reference: https://bind9.readthedocs.io/en/latest/reference.html#zone-statement-grammar
#
type Bind::Zone = Struct[{
  name => Pattern[/\.$/],
  Optional['allow-transfer'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
  Optional['allow-update'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
  Optional['also-notify'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
  Optional['auto-dnssec'] => Enum['allow', 'maintain', 'off'],
  Optional['class'] => Enum['IN', 'HS', 'hesiod', 'CHAOS'],
  Optional['file'] => String[1],
  Optional['forward'] => Enum['first', 'only'],
  Optional['forwarders'] => Array[Stdlib::Host],
  Optional['in-view'] => String[1],
  Optional['inline-signing'] => Variant[Boolean, Stdlib::Yes_no],
  Optional['key-directory'] => String[1],
  Optional['masters'] => Array[Stdlib::Host],
  Optional['primaries'] => Array[Stdlib::Host],
  Optional['purge'] => Boolean,
  Optional['resource-records'] => Array[Bind::Zone::ResourceRecord],
  Optional['serial-update-method'] => Enum['date', 'increment', 'unixtime'],
  Optional['ttl'] => String[1],
  Optional['type'] => Enum[
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
    'delegation-only'
  ],
  Optional['update-policy'] => Array[Bind::Zone::UpdatePolicy],
}]
