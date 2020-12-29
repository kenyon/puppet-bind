# @summary Type definition for BIND's `logging` statement
type Bind::Logging = Struct[{
  Optional['channels'] => Hash[Bind::Logging::ChannelName, Bind::Logging::ChannelPhrase],
  Optional['categories'] => Hash[Bind::Logging::Category, Bind::Logging::CategoryPhrase],
}]
