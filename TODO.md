<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# To do

## General

- `git grep -E 'TODO|FIXME'`
- DNSSEC setup support

## Zones

- use dynamic zone files for regular user-defined zones
  - use [dnsruby](https://rubygems.org/gems/dnsruby) to do zone updates
    - types and providers with the Resource API
  - use `named-checkzone` to validate the zone
    - use validate_cmd with file resources

## Config

- create structs and type aliases for named.conf statements.
  - keys
  - views
  - zones
  - logging
  - ...
- manage `rndc.conf`
