# @summary Type definition for BIND's `options` statement
type Bind::Options = Struct[{
  directory => Stdlib::Absolutepath,
  Optional['allow-query'] => Array[String[1]],
  Optional['zone-statistics'] => Variant[Boolean, Enum['yes', 'no', 'full', 'terse', 'none']],
}]
