# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

require 'spec_helper'

checkconf_cmd = '/usr/sbin/named-checkconf -z %'

def checkzone_cmd(zone_name)
  "/usr/sbin/named-checkzone #{zone_name} %"
end

config_dir = File.join('/etc', 'bind')
config_filename = 'named.conf'
config_file = File.join(config_dir, config_filename)
default_zone_names = [
  {
    'filename' => 'db.0',
    'zonename' => '0.in-addr.arpa',
  },
  {
    'filename' => 'db.127',
    'zonename' => '127.in-addr.arpa',
  },
  {
    'filename' => 'db.255',
    'zonename' => '255.in-addr.arpa',
  },
  {
    'filename' => 'db.local',
    'zonename' => 'localhost',
  },
]
default_zones = %r<zone "." \{
    type hint;
    file "/usr/share/dns/root\.hints";
\};

zone "localhost" \{
    type master;
    file "/etc/bind/db\.local";
\};

zone "127\.in-addr\.arpa" \{
    type master;
    file "/etc/bind/db\.127";
\};

zone "0\.in-addr\.arpa" \{
    type master;
    file "/etc/bind/db\.0";
\};

zone "255\.in-addr\.arpa" \{
    type master;
    file "/etc/bind/db\.255";
\};
>
group = 'bind'
package_name = 'bind9'
# key 20326
root_key = %r{AwEAAaz/tAm8yTn4Mfeh5eyI96WSVexTBAvkMgJzkKTOiW1vkIbzxeF3
                \+/4RgWOq7HrxRixHlFlExOLAJr5emLvN7SWXgnLh4\+B5xQlNVz8Og8kv
                ArMtNROxVQuCaSnIDdD5LKyWbRd2n9WGe2R8PzgCmr3EgVLrjyBxWezF
                0jLHwVN8efS3rCj/EWgvIWgb9tarpVUDK/b58Da\+sqqls3eNbuv7pr\+e
                oZG\+SrDK6nWeL3c6H5Apxz7LjVc1uTIdsIXxuOLYA4/ilBmSVIzuDWfd
                RUfhHdY6\+cn8HFRm\+2hM8AnXGXws9555KrUB5qihylGa8subX2Nn6UwN
                R1AkUTV74bU=}
user = 'bind'
working_dir = File.join('/var', 'cache', 'bind')

describe 'bind' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:service_name) do
        if os_facts[:os]['name'] == 'Debian' && os_facts[:os]['release']['major'] == '10'
          'bind9'
        else
          'named'
        end
      end

      context 'using defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('bind::install') }
        it { is_expected.to contain_class('bind::config') }
        it { is_expected.to contain_class('bind::service') }
        it { is_expected.to contain_class('bind::install').that_comes_before('Class[bind::config]') }
        it { is_expected.to contain_class('bind::config').that_notifies('Class[bind::service]') }
        it { is_expected.to contain_package(package_name).with_ensure('installed') }

        it do
          is_expected.to contain_file(File.join(config_dir, 'bind.keys')).with(
            ensure: 'file',
            content: root_key,
            validate_cmd: checkconf_cmd,
          )
        end

        default_zone_names.each do |names|
          it do
            is_expected.to contain_file(File.join(config_dir, names['filename'])).with(
              ensure: 'file',
              validate_cmd: checkzone_cmd(names['zonename']),
            )
          end
        end

        if os_facts[:os]['name'] == 'Debian' && os_facts[:os]['release']['major'] == '10'
          it do
            is_expected.to contain_file(File.join(config_dir, 'bind.keys')).with(
              ensure: 'file',
              content: %r{managed-keys},
              validate_cmd: checkconf_cmd,
            )
          end
        else
          it do
            is_expected.to contain_file(File.join(config_dir, 'bind.keys')).with(
              ensure: 'file',
              content: %r{trust-anchors},
              validate_cmd: checkconf_cmd,
            )
          end
        end

        it do
          is_expected.to contain_file(working_dir).with(
            ensure: 'directory',
            owner: 'root',
            group: group,
            mode: '0775',
          )
        end

        it do
          is_expected.to contain_service(service_name).with(
            ensure: 'running',
            enable: true,
          )
        end

        context 'named configuration' do
          it do
            is_expected.to contain_file(config_dir).with(
              ensure: 'directory',
              force: true,
              owner: 'root',
              group: group,
              mode: '2755',
              purge: true,
              recurse: true,
            )
          end

          it do
            is_expected.to contain_file(config_file)
              .with_ensure('file')
              .with_content(%r{# Managed by Puppet})
              .with_content(default_zones)
              .without_content(%r{include ".*";})
              .with_validate_cmd(checkconf_cmd)
          end

          it do
            is_expected.to contain_file(File.join(config_dir, 'rndc.key')).with(
              ensure: 'file',
              owner: 'root',
              group: group,
              mode: '0600',
              validate_cmd: checkconf_cmd,
            )
          end

          it do
            is_expected.to contain_exec('/usr/sbin/rndc-confgen -a')
              .with_creates(File.join(config_dir, 'rndc.key'))
          end
        end

        if os_facts[:os]['family'] == 'Debian'
          it do
            is_expected.to contain_file(config_file).with_content(%r{directory "#{working_dir}";})
          end

          it do
            is_expected.to contain_file(File.join('/etc', 'default', service_name))
              .with_ensure('file')
              .with_content(%r{^RESOLVCONF=no$})
              .with_content(%r{^OPTIONS="-u '#{user}' -c '#{config_file}' "$})
          end
        end
      end

      context 'without default zones' do
        let(:params) do
          {
            default_zones: false,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(config_file).without_content(default_zones) }
        it { is_expected.not_to contain_file(File.join(config_dir, 'db.0')) }
        it { is_expected.not_to contain_file(File.join(config_dir, 'db.127')) }
        it { is_expected.not_to contain_file(File.join(config_dir, 'db.255')) }
        it { is_expected.not_to contain_file(File.join(config_dir, 'db.local')) }
      end

      context 'with custom includes' do
        context 'undef' do
          let(:params) do
            {
              includes: :undef,
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file(config_file).without_content(%r{include}) }
        end

        context 'invalid type' do
          let(:params) do
            {
              includes: 'not_an_absolute_path',
            }
          end

          it { is_expected.not_to compile }
        end

        context 'single file' do
          custom_includes_file = File.join('/etc', 'bind', 'whatever')
          let(:params) do
            {
              includes: custom_includes_file,
            }
          end

          it { is_expected.to compile.with_all_deps }

          it do
            is_expected.to contain_file(config_file)
              .with_content(%r{^include "#{custom_includes_file}";$})
          end
        end

        context 'array' do
          custom_includes_array = [
            File.join('/etc', 'bind', 'whatever'),
            File.join('/etc', 'bind', 'another'),
          ]
          let(:params) do
            {
              includes: custom_includes_array,
            }
          end

          it { is_expected.to compile.with_all_deps }

          it do
            is_expected.to contain_file(config_file)
              .with_content(%r{^include "#{custom_includes_array[0]}";$})
              .with_content(%r{^include "#{custom_includes_array[1]}";$})
          end
        end
      end

      context 'with custom zones' do
        context 'undef (and without default zones to make test easier)' do
          let(:params) do
            {
              default_zones: false,
              zones: :undef,
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_file(config_file).without_content(%r{^zone}) }
        end

        context 'invalid type' do
          let(:params) do
            {
              zones: 'strings are invalid',
            }
          end

          it { is_expected.not_to compile }
        end

        context 'array of zones' do
          let(:params) do
            {
              zones: [
                { name: '.', type: 'mirror' },
                {
                  name: 'example.com.',
                  type: 'primary',
                  file: 'specified-file-example',
                  'allow-transfer' => ['2001:db8::/64'],
                  'allow-update' => ['2001:db8:2::/64'],
                  'also-notify' => ['2001:db8:1::/64'],
                  'auto-dnssec' => 'maintain',
                  'inline-signing' => true,
                  'key-directory' => 'example',
                },
                {
                  name: 'example.net.',
                  type: 'secondary',
                  forward: 'only',
                  forwarders: ['192.0.2.3', '192.0.2.4'],
                },
                { name: 'example.org.', class: 'IN', 'in-view' => 'view0' },
                {
                  name: 'example.xyz.',
                  type: 'secondary',
                  primaries: ['2001:db8::1'],
                },
                {
                  name: 'example.lol.',
                  type: 'primary',
                  'update-policy' => [
                    permission: 'deny',
                    identity: 'host-key',
                    ruletype: 'name',
                    name: 'ns1.example.com.',
                    types: 'A',
                  ],
                },
                {
                  name: 'example.local.',
                  type: 'primary',
                  'update-policy' => ['local'],
                },
                {
                  name: 'example.both.',
                  type: 'primary',
                  'update-policy' => [
                    'local',
                    {
                      permission: 'deny',
                      identity: 'host-key',
                      ruletype: 'name',
                      name: 'ns1.example.com.',
                    },
                  ],
                },
                {
                  name: 'example.local2.',
                  type: 'primary',
                  'update-policy' => [
                    permission: 'grant',
                    identity: 'local-ddns',
                    ruletype: 'zonesub',
                    types: 'any',
                  ],
                  'serial-update-method' => 'unixtime',
                },
              ],
            }
          end

          it { is_expected.to compile.with_all_deps }

          it do
            is_expected.to contain_file(config_file).with_content(%r<^zone "\." \{
    type mirror;
    file "db\.root";
\};$>).with_content(%r<^zone "example\.com\." \{
    type primary;
    file "specified-file-example";
    allow-transfer \{
        2001:db8::/64;
    \};
    allow-update \{
        2001:db8:2::/64;
    \};
    also-notify \{
        2001:db8:1::/64;
    \};
    auto-dnssec maintain;
    inline-signing true;
    key-directory "example";
\};$>).with_content(%r<^zone "example\.net\." \{
    type secondary;
    file "db\.example\.net\.";
    forward only;
    forwarders \{
        192\.0\.2\.3;
        192\.0\.2\.4;
    \};
\};$>).with_content(%r<^zone "example\.org\." IN \{
    in-view "view0";
\};$>).with_content(%r<^zone "example\.xyz\." \{
    type secondary;
    file "db\.example\.xyz\.";
    primaries \{
        2001:db8::1;
    \};
\};>).with_content(%r<^zone "example\.lol\." \{
    type primary;
    file "db\.example\.lol\.";
    update-policy \{
        deny host-key name ns1\.example\.com\. A;
    \};
\};>).with_content(%r<^zone "example\.local\." \{
    type primary;
    file "db\.example\.local\.";
    update-policy local;
\};>).with_content(%r<^zone "example\.both\." \{
    type primary;
    file "db\.example\.both\.";
    update-policy local;
    update-policy \{
        deny host-key name ns1\.example\.com\.\s*;
    \};
\};>).with_content(%r<^zone "example\.local2\." \{
    type primary;
    file "db\.example\.local2\.";
    serial-update-method unixtime;
    update-policy \{
        grant local-ddns zonesub\s+any;
    \};
\};>)
          end
        end
      end

      context 'with custom logging' do
        context 'only categories defined' do
          let(:params) do
            {
              logging: {
                categories: {
                  security: {
                    channels: ['my_security_channel', 'default_syslog'],
                  },
                  notify: {
                    channels: ['null'],
                  },
                },
              },
            }
          end

          it { is_expected.to compile.with_all_deps }

          it do
            is_expected.to contain_file(config_file).with_content(%r<^logging \{
    category security \{
        my_security_channel;
        default_syslog;
    \};
    category notify \{
        null;
    \};
\};>)
          end
        end

        context 'only channels defined' do
          let(:params) do
            {
              logging: {
                channels: {
                  chan1: 'null',
                  chan2: {
                    file: {
                      name: 'log',
                    },
                  },
                },
              },
            }
          end

          it { is_expected.to compile.with_all_deps }

          it do
            is_expected.to contain_file(config_file).with_content(%r<^logging \{
    channel chan1 \{
        null;
    \};
    channel chan2 \{
        file "log"\s*;
    \};
\};>)
          end
        end

        context 'channels and categories defined' do
          let(:params) do
            {
              logging: {
                categories: {
                  rpz: {},
                  queries: {
                    channels: [
                      'my_query_channel',
                      'default_syslog',
                    ],
                  },
                  'query-errors' => {
                    channels: ['null'],
                  },
                },
                channels: {
                  an_example_channel: {
                    buffered: true,
                    file: {
                      name: 'example.log',
                      versions: 'unlimited',
                      size: '100M',
                      suffix: 'timestamp',
                    },
                    'print-category' => true,
                    'print-time' => 'iso8601-utc',
                    severity: 'debug 3',
                  },
                  my_query_channel: {
                    file: {
                      name: 'query.log',
                      versions: 2,
                      size: '1m',
                    },
                    'print-time' => true,
                    severity: 'info',
                  },
                },
              },
            }
          end

          it { is_expected.to compile.with_all_deps }

          it do
            is_expected.to contain_file(config_file)
              .with_content(%r<^logging \{
    category rpz \{
    \};
    category queries \{
        my_query_channel;
        default_syslog;
    \};
    category query-errors \{
        null;
    \};
    channel an_example_channel \{
        buffered yes;
        file "example\.log" versions unlimited size 100M suffix timestamp;
        print-category yes;
        print-time iso8601-utc;
        severity debug 3;
    \};
    channel my_query_channel \{
        file "query\.log" versions 2 size 1m;
        print-time true;
        severity info;
    \};
\};>)
          end
        end
      end

      context 'with custom options' do
        let(:params) do
          {
            options: {
              'allow-transfer' => ['2001:db8::/64'],
              'allow-update' => ['2001:db8:2::/64'],
              'allow-query' => [
                'localhost',
                'localnets',
                '2001:db8::/32',
                '192.0.2.0/24',
              ],
              'also-notify' => ['2001:db8:1::/64'],
              # PDK's super old rubocop fails to parse this using newer hash syntax :(
              'auto-dnssec' => 'maintain',
              'directory' => '/meh',
              'inline-signing' => true,
              'key-directory' => 'example',
              'serial-update-method' => 'date',
              'zone-statistics' => 'full',
            },
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_file(config_file)
            .with_content(%r{directory "/meh";})
            .with_content(%r{auto-dnssec maintain;})
            .with_content(%r{inline-signing true;})
            .with_content(%r{key-directory "example";})
            .with_content(%r{zone-statistics full;})
            .with_content(%r{serial-update-method date;})
            .with_content(%r<allow-query \{
        localhost;
        localnets;
        2001:db8::/32;
        192\.0\.2\.0/24;
    \};>).with_content(%r<allow-transfer \{
        2001:db8::/64;
    \};>).with_content(%r<allow-update \{
        2001:db8:2::/64;
    \};>).with_content(%r<also-notify \{
        2001:db8:1::/64;
    \};>)
        end

        context 'directory not specified in params, should be provided by defaults' do
          let(:params) do
            {
              options: { 'zone-statistics' => 'full' },
            }
          end

          it { is_expected.to compile.with_all_deps }

          it do
            is_expected.to contain_file(config_file)
              .with_content(%r{directory "#{working_dir}"})
              .with_content(%r{zone-statistics full;})
          end
        end
      end

      context 'with custom service_options' do
        custom_service_options = '-6 -s'
        let(:params) do
          {
            service_options: custom_service_options,
          }
        end

        it { is_expected.to compile.with_all_deps }

        if os_facts[:os]['family'] == 'Debian'
          it do
            is_expected.to contain_file(
              File.join('/etc', 'default', service_name),
            ).with_content(%r{^OPTIONS="-u '#{user}' -c '#{config_file}' #{custom_service_options}"$})
          end
        end
      end

      context 'with resolvconf_service_enable => true', if: os_facts[:os]['family'] == 'Debian' do
        let(:params) do
          {
            resolvconf_service_enable: true,
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_file(
            File.join('/etc', 'default', service_name),
          ).with_content(%r{^RESOLVCONF=yes$})
        end

        it do
          is_expected.to contain_package(
            'openresolv',
          ).that_comes_before("Package[#{package_name}]")
        end

        it do
          is_expected.to contain_service("#{service_name}-resolvconf").with(
            ensure: 'running',
            enable: true,
            require: 'Package[openresolv]',
          )
        end

        context 'with a custom resolvconf_package_name' do
          custom_resolvconf_package_name = 'myresolvconf'
          let(:params) do
            super().merge(resolvconf_package_name: custom_resolvconf_package_name)
          end

          it { is_expected.to compile.with_all_deps }

          it do
            is_expected.to contain_package(
              custom_resolvconf_package_name,
            ).that_comes_before("Package[#{package_name}]")
          end

          it do
            is_expected.to contain_service(
              "#{service_name}-resolvconf",
            ).with_require("Package[#{custom_resolvconf_package_name}]")
          end
        end
      end

      context 'with a custom config_dir' do
        custom_config_dir = File.join('/etc', 'blag')
        let(:params) do
          {
            config_dir: custom_config_dir,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(File.join(custom_config_dir, config_filename)) }
      end

      context 'with a custom service_config_file' do
        custom_service_config_file = '/myconfig'
        let(:params) do
          {
            service_config_file: custom_service_config_file,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(custom_service_config_file) }

        if os_facts[:os]['family'] == 'Debian'
          it do
            is_expected.to contain_file(
              File.join('/etc', 'default', service_name),
            ).with_content(%r{^OPTIONS="-u '#{user}' -c '#{custom_service_config_file}' "$})
          end
        end
      end

      context 'with custom service_user and service_group' do
        custom_service_user = 'zaphod'
        custom_service_group = 'hitchhikers'
        let(:params) do
          {
            service_user: custom_service_user,
            service_group: custom_service_group,
          }
        end

        it { is_expected.to compile.with_all_deps }

        if os_facts[:os]['family'] == 'Debian'
          it do
            is_expected.to contain_file(
              File.join('/etc', 'default', service_name),
            ).with_content(%r{^OPTIONS="-u '#{custom_service_user}' -c '#{config_file}' "$})
          end
        end

        it do
          is_expected.to contain_file(working_dir).with(
            ensure: 'directory',
            owner: 'root',
            group: custom_service_group,
            mode: '0775',
          )
        end
      end

      context 'with a custom package_name' do
        custom_package_name = 'quux'
        let(:params) do
          {
            package_name: custom_package_name,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package(custom_package_name) }
      end

      context 'with a custom service_name' do
        custom_service_name = 'quuz'
        let(:params) do
          {
            service_name: custom_service_name,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service(custom_service_name) }
      end

      context 'with package_backport => true', if: os_facts[:os]['name'] == 'Debian' do
        let(:params) do
          {
            package_backport: true,
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_class(
            'apt::backports',
          ).that_comes_before('Class[bind::install]')
        end

        it do
          is_expected.to contain_package(
            package_name,
          ).with_install_options(
            ['--target-release', "#{facts[:os]['distro']['codename']}-backports"],
          )
        end

        it { is_expected.to contain_file(File.join(config_dir, 'bind.keys')).with_content(%r{trust-anchors}) }
      end

      context 'when package_manage => false' do
        let(:params) do
          {
            package_manage: false,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_package(package_name) }
        it { is_expected.to contain_service(service_name) }
      end

      context 'when service_enable => false' do
        let(:params) do
          {
            service_enable: false,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service(service_name).with_enable(false) }
      end

      context 'when service_ensure => stopped' do
        let(:params) do
          {
            service_ensure: 'stopped',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service(service_name).with_ensure('stopped') }
      end

      context 'when service_manage => false' do
        let(:params) do
          {
            service_manage: false,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_service(service_name) }
      end

      context 'when uninstalling' do
        let(:params) do
          {
            package_ensure: 'absent',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package(package_name).with_ensure('absent') }
        it do
          is_expected.to contain_service(service_name).with(
            ensure: 'stopped',
            enable: false,
          )
        end
      end
    end
  end
end
