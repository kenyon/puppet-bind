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

      if $zone['type'] in ['primary', 'master', 'redirect'] and $zone['resource-records'] {
        unless $zone['resource-records'].any |$rr| {$rr['type'].upcase == 'SOA'} {
          fail("zone ${zone['name']}: must define a SOA record")
        }

        unless $zone['allow-update'] or $zone['update-policy'] {
          fail("zone ${zone['name']}: must be updatable locally via allow-update or update-policy")
        }
      }
    }
  }
}
