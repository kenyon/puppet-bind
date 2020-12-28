# @summary Type definition for BIND's `zone` statement
type Bind::Zone = Struct[{
  name => String[1],
  Optional['class'] => Enum['IN', 'HS', 'hesiod', 'CHAOS'],
  Optional['in-view'] => String[1],
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
  Optional['file'] => Stdlib::Absolutepath,
  Optional['forward'] => Enum['first', 'only'],
  Optional['forwarders'] => Array[Stdlib::Host],
}]
