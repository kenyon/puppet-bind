# SPDX-License-Identifier: AGPL-3.0-or-later

# @summary Type definition for BIND's `logging` `channel` phrase
#
# Reference: https://bind9.readthedocs.io/en/latest/reference.html#the-channel-phrase
#
type Bind::Logging::ChannelPhrase = Variant[Enum['null', 'stderr', 'syslog'], Struct[{
  Optional['buffered'] => Boolean,
  Optional['file'] => Struct[{
    'name' => String[1],
    Optional['versions'] => Variant[Enum['unlimited'], Integer[1]],
    Optional['size'] => Bind::Size,
    Optional['suffix'] => Enum['increment', 'timestamp'],
  }],
  Optional['print-category'] => Boolean,
  Optional['print-severity'] => Boolean,
  Optional['print-time'] => Variant[Boolean, Stdlib::Yes_no, Enum['iso8601', 'iso8601-utc', 'local']],
  Optional['severity'] => String[1],
  Optional['syslog'] => Stdlib::Syslogfacility,
}]]
