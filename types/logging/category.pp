# @summary Type definition for BIND's logging categories
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
