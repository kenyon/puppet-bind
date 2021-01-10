# SPDX-License-Identifier: GPL-3.0-or-later

# @summary Type definition for BIND's `logging` categories
#
# Reference: https://bind9.readthedocs.io/en/latest/reference.html#the-category-phrase
#
type Bind::Logging::Category = Enum[
  'client',
  'cname',
  'config',
  'database',
  'default',
  'delegation-only',
  'dispatch',
  'dnssec',
  'dnstap',
  'edns-disabled',
  'general',
  'lame-servers',
  'network',
  'notify',
  'nsid',
  'queries',
  'query-errors',
  'rate-limit',
  'resolver',
  'rpz',
  'rpz-passthru',
  'security',
  'serve-stale',
  'spill',
  'trust-anchor-telemetry',
  'unmatched',
  'update',
  'update-security',
  'xfer-in',
  'xfer-out',
  'zoneload',
]
