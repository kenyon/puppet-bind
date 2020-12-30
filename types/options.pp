# @summary Type definition for BIND's `options` statement
type Bind::Options = Struct[{
  Optional['allow-transfer'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
  Optional['allow-query'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
  Optional['also-notify'] => Array[Variant[Stdlib::Host, Stdlib::IP::Address]],
  Optional['auto-dnssec'] => Enum['allow', 'maintain', 'off'],
  Optional['directory'] => Stdlib::Absolutepath,
  Optional['inline-signing'] => Variant[Boolean, Stdlib::Yes_no],
  Optional['key-directory'] => Stdlib::Absolutepath,
  Optional['zone-statistics'] => Variant[Boolean, Stdlib::Yes_no, Enum['full', 'terse', 'none']],
}]
