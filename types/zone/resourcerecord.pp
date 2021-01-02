# @summary Type definition for a resource record
type Bind::Zone::ResourceRecord = Struct[{
  'data' => Variant[String[1], Array[String[1]]],
  'type' => String[1],
  Optional['name'] => String[1],
  Optional['class'] => String[1],
  Optional['ttl'] => String[1],
}]
