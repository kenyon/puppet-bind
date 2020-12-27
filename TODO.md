<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# To do

## General

- `git grep -E 'TODO|FIXME'`
- manage the entire `/etc/bind` directory
  - replicate the default `db.*` files and associated `zone` statements
- DNSSEC setup support
- implement option for local root zone support: https://tools.ietf.org/html/rfc8806

## Zones

- use dynamic zone files for regular user-defined zones
  - use [dnsruby](https://rubygems.org/gems/dnsruby) to do zone updates
    - types and providers with the Resource API
  - use `named-checkzone` to validate the zone

## Config

- use `named-checkconf` to validate the resulting config
- create structs and type aliases for named.conf statements.
  - includes
  - keys
  - views
  - zones
  - logging
  - options
  - ...
- manage `rndc.conf`
