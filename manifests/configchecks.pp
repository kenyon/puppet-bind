# SPDX-License-Identifier: GPL-3.0-or-later
#
# @summary Some checks for BIND configuration validity
#
# @api private
#
class bind::configchecks {
  assert_private()

  if $bind::zones {
    $bind::zones.each |$zone| {
      unless $zone['type'] or $zone['in-view'] {
        fail("zone ${zone['name']}: must specify either in-view or type")
      }
    }
  }
}
