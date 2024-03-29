<!-- SPDX-License-Identifier: AGPL-3.0-or-later -->

# bind

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with bind](#setup)
   - [What bind affects](#what-bind-affects)
   - [Setup requirements](#setup-requirements)
   - [Beginning with bind](#beginning-with-bind)
1. [Usage - Configuration options and additional functionality](#usage)
   - [Recursive, caching only](#recursive-caching-only)
   - [Authoritative only](#authoritative-only)
   - [Authoritative and caching](#authoritative-and-caching)
   - [The `resource_record` type](#the-resource_record-type)
   - [The `bind::key` defined type](#the-bindkey-defined-type)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)
   - [Running tests](#running-tests)
   - [Generating documentation](#generating-documentation)
   - [Release process](#release-process)
1. [Alternatives](#alternatives)
1. [BIND documentation](#bind-documentation)
1. [License](#license)

## Description

This module manages the [BIND](https://www.isc.org/bind/) DNS server and associated [DNS
zones](https://en.wikipedia.org/wiki/DNS_zone).

## Setup

### What bind affects

- the BIND package, service, configuration, and zone files
- a [resolvconf](https://en.wikipedia.org/wiki/Resolvconf) package, by default
  [openresolv](https://roy.marples.name/projects/openresolv/), is installed if
  `resolvconf_service_enable` is `true`. This causes the localhost's BIND to be used in
  `/etc/resolv.conf`.
- if configured to install the backported package, also affects
  [APT](https://tracker.debian.org/pkg/apt) sources by ensuring that backports are available.

### Setup requirements

See [`metadata.json`](metadata.json) for supported operating systems, supported Puppet versions,
and Puppet module dependencies.

### Beginning with bind

For a default configuration that provides recursive, caching name resolution service:

```puppet
include bind
```

On Debian, install the `bind9` package from the backports repository (ensures that the
`$facts['os']['distro']['codename']-backports` apt source is configured using the
[`puppetlabs-apt`](https://github.com/puppetlabs/puppetlabs-apt) module, but will fail if a
backported package does not exist for your particular
`$facts['os']['distro']['codename']-backports` repo; check on the [Debian package
tracker](https://tracker.debian.org/pkg/bind9)):

```puppet
class { 'bind':
  package_backport => true,
}
```

## Usage

See the [reference](REFERENCE.md) for available class parameters and defaults. For
platform-specific defaults, see the [`data`](data) directory, which is organized according to
[`hiera.yaml`](hiera.yaml).

The test suite in the [`spec`](spec) directory is a good source for usage examples.

To manage the resource records of a zone with this module, the zone must be dynamically updatable
by the host being managed, via either the `allow-update` or `update-policy` configuration
options.

### Recursive, caching only

Using a minimal configuration with BIND defaults:

```puppet
include bind
```

TODO: provide more examples.

### Authoritative only

Note that support for authoritative servers is incomplete in this module.

When creating a new zone with BIND, the zone file must have a `$TTL`, a SOA record, an NS record,
and an address record for that host used in the NS record. All of these have defaults (see the
`zone_default_*` parameters of [`init.pp`](manifests/init.pp) and the [initial zone
template](templates/db.empty.epp)) so you don't have to specify them. The default initial zone
creates `A` and `AAAA` records based on the host's facts. Those default NS records are only used
if no NS records are provided for the zone's origin. You should specify your own SOA and NS
records unless you happen to want those defaults. Note that if you want to provide your own NS
records at the zone origin, you also have to provide your own SOA record.

```puppet
class { 'bind':
  authoritative => true,
  # TODO: add settings to disable recursive query support
}
```

TODO: provide more examples.

### Authoritative and caching

```puppet
class { 'bind':
  authoritative => true,
}
```

TODO: provide more examples.

### The `resource_record` type

DNS resource records can be created with the `resource_record` Puppet type.

Equivalent examples:

```puppet
resource_record { 'www.example.com. AAAA':
  data => '2001:db8::1',
}
```

```puppet
resource_record { 'my record':
  zone   => 'example.com.',
  record => 'www',
  type   => 'AAAA',
  data   => '2001:db8::1',
}
```

The title of `resource_record` resources can be in one of the following formats:

1. Name, zone, type: `www.example.com. AAAA` (AAAA record `www` in the `example.com.` zone)
1. Name and zone: `www.example.com.` (record `www` in the `example.com.` zone with type specified as a parameter)
1. Name and type: `www AAAA` (AAAA record `www` in a zone specified as a parameter)
1. Name: `www` (record `www` with zone and type specified as parameters)
1. Any other format means all of the required parameters need to be specified in the resource definition.

### The `bind::key` defined type

TSIG keys for dynamic zone updates used by clients can be added to the configuration as follows.

```puppet
bind::key { 'key_name':
  algorithm => 'hmac-sha512',
  secret    => 'ZlfCDgP7d3g7LjV4YMLg62EbpLZRCt9BMh3MyqiZfPX5Y2IcTyx/la6PMsfAqLMM9QDadZiNiLVzD4IPoI/4hg==',
}
```

The key's secret needs to be generated using the BIND tool `tsig-keygen`; example:

```bash
tsig-keygen -a $algorithm [$key_name]
```

## Limitations

See [`metadata.json`](metadata.json) for supported operating systems, supported Puppet versions,
and Puppet module dependencies.

Downgrading the package by setting `package_backport => false` (after it had been `true`) is not
supported by this module, but you can of course do such a downgrade manually outside of Puppet.

Changing the value provided for a zone's `$TTL` directive after initial zone creation is not
supported by this module (because the zone file is only created initially from a template and
then never replaced, only updated dynamically using the [RFC
2136](https://tools.ietf.org/html/rfc2136) method), but you can do this manually outside of
Puppet.

## Development

The development of this module attempts to be
[test-driven](https://en.wikipedia.org/wiki/Test-driven_development) as much as possible.
Therefore, changes should generally be accompanied by tests. The test suite is located in the
[`spec`](spec) directory. Acceptance tests (in the [`acceptance`](spec/acceptance) directory) use
[Serverspec](https://serverspec.org/), while unit tests (everything else) use
[rspec-puppet](https://rspec-puppet.com/).

### Running tests

[PDK](https://puppet.com/docs/puppet/latest/pdk_install.html) and
[Docker](https://docs.docker.com/engine/) must be installed and working.
[GNU Parallel](https://tracker.debian.org/pkg/parallel) is used to run acceptance tests in
parallel by default. This can be disabled with the `--no-parallel` option.

```console
./run_tests
```

### Generating documentation

```console
pdk bundle exec rake strings:generate:reference
```

See also:

- [Puppet Strings](https://puppet.com/docs/puppet/latest/puppet_strings.html)

### Release process

1. `git checkout main`
1. Update the version in `metadata.json` to the to-be-released version.
1. `pdk bundle exec rake changelog`
1. `git commit --all`
1. `git tag -a <version>`
1. `pdk build`
1. `git push` (I have `git config --global push.followTags true` so that the tag will also be
   pushed. This also causes the `publish.yaml` GitHub workflow to build and publish a release to the
   Puppet Forge.)
1. `gh release create <version> pkg/kenyon-bind-<version>.tar.gz` (using [GitHub CLI](https://cli.github.com/))

## Alternatives

[Other BIND modules on Puppet Forge](https://forge.puppet.com/modules?q=bind)

## BIND documentation

- [BIND Administrator Reference Manual](https://bind9.readthedocs.io/)

## Acknowledgments

The following files came from the [Debian package](https://tracker.debian.org/pkg/bind9) and are
licensed under the [MPL-2.0](https://www.mozilla.org/en-US/MPL/2.0/).

- [`files/etc/bind/db.0`](files/etc/bind/db.0)
- [`files/etc/bind/db.127`](files/etc/bind/db.127)
- [`files/etc/bind/db.255`](files/etc/bind/db.255)
- [`files/etc/bind/db.local`](files/etc/bind/db.local)

## License

Copyright ⓒ 2021 Kenyon Ralph

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
