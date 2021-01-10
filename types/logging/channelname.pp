# SPDX-License-Identifier: GPL-3.0-or-later

# @summary Type definition for BIND's `logging` `channel` names
#
# Reference: https://bind9.readthedocs.io/en/latest/reference.html#the-channel-phrase
#
type Bind::Logging::ChannelName = Pattern[/\A\w+\Z/]
