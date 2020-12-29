# @summary Type definition for BIND's `logging` `category` phrase
#
# Reference: https://bind9.readthedocs.io/en/latest/reference.html#the-category-phrase
#
type Bind::Logging::CategoryPhrase = Struct[{
  Optional['channels'] => Array[String[1]],
}]
