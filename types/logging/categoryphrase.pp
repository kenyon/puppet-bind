# @summary Type definition for BIND's logging category phrase
type Bind::Logging::CategoryPhrase = Struct[{
  Optional['channels'] => Array[String[1]],
}]
