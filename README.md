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

This module manages the BIND DNS server and associated DNS zones.

## Setup

### What bind affects

- the BIND package, service, and configuration files

If configured to install the backported package, also affects APT sources by ensuring that
backports are available.

### Setup requirements

See [metadata.json](metadata.json) for Puppet module dependencies.

### Beginning with bind

```puppet
include bind
```

## Usage

Include usage examples for common use cases in the **Usage** section. Show your
users how to use your module to solve problems, and be sure to include code
examples. Include three to five examples of the most important or common tasks a
user can accomplish with your module. Show users how to accomplish more complex
tasks that involve different types, classes, and functions working in tandem.

## Limitations

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
