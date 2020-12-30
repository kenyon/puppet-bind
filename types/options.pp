# @summary Type definition for BIND's `options` statement
type Bind::Options = Struct[{
  Optional['allow-query'] => Array[String[1]],
  Optional['auto-dnssec'] => Enum['allow', 'maintain', 'off'],
  Optional['directory'] => Stdlib::Absolutepath,
  Optional['inline-signing'] => Variant[Boolean, Stdlib::Yes_no],
  Optional['key-directory'] => Stdlib::Absolutepath,
  Optional['zone-statistics'] => Variant[Boolean, Stdlib::Yes_no, Enum['full', 'terse', 'none']],
}]
