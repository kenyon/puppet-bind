<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->

## v0.4.0

- Test enhancements
- `bind::zone`: change `$purge` default to false so that unmanaged resource records are not
  purged by default
- `bind::zone`: add parameter `$manage`. When true, means you want to manage the content of the
  zone with this module.
- `named.conf` template: whitespace cleanup, logic simplification

## v0.3.0

- Allow disabling the default root hint zone so that you can have a mirror of the root zone
- Fix handling of backport packages
- Better ordering of named.conf fragments
- `resource_record` type and provider work. Still incomplete.

## v0.2.1

- Correctly update `metadata.json` and publish to Puppet Forge

## v0.2.0

### Features

- Rework package management parameters
- Add GitHub Actions workflows

### Known Issues

- Types and providers needed to manage DNS zones not complete

## v0.1.0

### Features

- Recursive server management

### Known Issues

- Types and providers needed to manage DNS zones not complete
