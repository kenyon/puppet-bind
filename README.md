# bind

[![pipeline status](https://gitlab.com/kenyon/puppet-bind/badges/main/pipeline.svg)](https://gitlab.com/kenyon/puppet-bind/-/commits/main)

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with bind](#setup)
   - [What bind affects](#what-bind-affects)
   - [Setup requirements](#setup-requirements)
   - [Beginning with bind](#beginning-with-bind)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)
1. [License](#license)

## Description

This module manages the [BIND](https://www.isc.org/bind/) DNS server and associated [DNS
zones](https://en.wikipedia.org/wiki/DNS_zone).

## Setup

### What bind affects

- the BIND package, service, and configuration files

If configured to install the backported package, also affects
[APT](https://tracker.debian.org/pkg/apt) sources by ensuring that backports are available.

### Setup requirements

See [`metadata.json`](metadata.json) for supported operating systems, supported Puppet versions,
and Puppet module dependencies.

### Beginning with bind

```puppet
include bind
```

## Usage

This module is designed to use the [default Debian `bind9` package
configuration](https://salsa.debian.org/dns-team/bind9/-/tree/debian/main/debian/extras/etc) as a
basis.

See also:

- [Reference](REFERENCE.md)

For parameter defaults, see the [`data`](data) directory, which is organized according to
[`hiera.yaml`](hiera.yaml).

## Limitations

See [`metadata.json`](metadata.json) for supported operating systems, supported Puppet versions,
and Puppet module dependencies.

Downgrading the package by setting `package_backport => false` (after it had been `true`) is not
supported by this module, but you can of course do this downgrade manually.

## Development

### Running tests

```console
pdk validate --parallel \
&& pdk test unit --parallel \
&& pdk bundle exec rake litmus:tear_down \
&& pdk bundle exec rake 'litmus:provision_list[default]' \
&& pdk bundle exec rake litmus:install_agent \
&& pdk bundle exec rake litmus:install_module \
&& pdk bundle exec rake litmus:acceptance:parallel \
&& pdk bundle exec rake litmus:tear_down
```

See also:

- [Puppet Development Kit](https://puppet.com/docs/puppet/latest/pdk_overview.html)

### Generating documentation

```console
pdk bundle exec rake strings:generate:reference
```

See also:

- [Puppet Strings](https://puppet.com/docs/puppet/latest/puppet_strings.html)

## Alternatives

[Other BIND modules on Puppet Forge](https://forge.puppet.com/modules?q=bind)

## License

Copyright ⓒ 2020 Kenyon Ralph

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.
