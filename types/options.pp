# @summary Type definition for BIND's `options` statement
type Bind::Options = Struct[{
  Optional['directory'] => Stdlib::Absolutepath,
  Optional['allow-query'] => Array[String[1]],
  Optional['zone-statistics'] => Variant[Boolean, Stdlib::Yes_no, Enum['full', 'terse', 'none']],
}]
