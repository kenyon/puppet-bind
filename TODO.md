<!-- SPDX-License-Identifier: GPL-3.0-or-later -->

# To do

## General

- `git grep -E 'TODO|FIXME'`
- DNSSEC setup support
- update [`metadata.json`](metadata.json) with new URLs after moving to GitHub
- publish on Forge

## Zones

- use dynamic zones for regular user-defined zones
  - have a `purge` parameter which purges unmanaged resource records, except for the SOA record.
    otherwise unmanaged resource records are left alone. similar to the `purge` parameter for
    directories with the `file` resource.
  - use [dnsruby](https://rubygems.org/gems/dnsruby) to do zone updates
    - types and providers with the Resource API
    - use `package` resource with the `puppet_gem` provider to install dnsruby

## Config

- create structs and type aliases for named.conf statements.
  - keys
  - views
  - ...
- manage `rndc.conf`

## Notes to self

- my config options: set serial-update-method date;
- my zone:
  - leave zone-default `$TTL` directive to two days, but specify RR-specific TTLs for home
    stuff that can change
  - use relative names in the SOA for primary server and contact email
