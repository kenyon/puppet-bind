<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# To do

## General

- `git grep -E 'TODO|FIXME'`
- DNSSEC setup support
- update [`metadata.json`](metadata.json) with new URLs after moving to GitHub
- publish on Forge

## Zones

- use dynamic zone files for regular user-defined zones
  - use [dnsruby](https://rubygems.org/gems/dnsruby) to do zone updates
    - types and providers with the Resource API
    - use `package` resource with the `puppet_gem` provider to install dnsruby
  - use `named-checkzone` to validate the zone

## Config

- create structs and type aliases for named.conf statements.
  - keys
  - views
  - ...
- manage `rndc.conf`
