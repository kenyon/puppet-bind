# SPDX-License-Identifier: AGPL-3.0-or-later

# @summary Type definition for BIND's `logging` statement
#
# Reference: https://bind9.readthedocs.io/en/latest/reference.html#logging-statement-grammar
#
type Bind::Logging = Struct[
  {
    Optional['channels'] => Hash[Bind::Logging::ChannelName, Bind::Logging::ChannelPhrase],
    Optional['categories'] => Hash[Bind::Logging::Category, Bind::Logging::CategoryPhrase],
  }
]
