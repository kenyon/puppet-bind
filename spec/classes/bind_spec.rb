# frozen_string_literal: true

# SPDX-License-Identifier: AGPL-3.0-or-later

require 'spec_helper'

default_zone_filenames_to_names = {
  'db.0' => '0.in-addr.arpa',
  'db.127' => '127.in-addr.arpa',
  'db.255' => '255.in-addr.arpa',
  'db.local' => 'localhost',
}

default_zones = Regexp.new(Regexp.escape(<<~DEFAULT_ZONES))
  zone "localhost" {
      type master;
      file "/etc/bind/db.local";
  };

  zone "127.in-addr.arpa" {
      type master;
      file "/etc/bind/db.127";
  };

  zone "0.in-addr.arpa" {
      type master;
      file "/etc/bind/db.0";
  };

  zone "255.in-addr.arpa" {
      type master;
      file "/etc/bind/db.255";
  };
  DEFAULT_ZONES

group = 'bind'
package_name = 'bind9'

root_hint_zone = Regexp.new(Regexp.escape(<<~ROOT_HINT_ZONE))
  zone "." {
      type hint;
      file "/usr/share/dns/root.hints";
  };
  ROOT_HINT_ZONE

# key 20326
root_key = Regexp.new(Regexp.escape('AwEAAaz/tAm8yTn4Mfeh5eyI96WSVexTBAvkMgJzkKTOiW1vkIbzxeF3
                +/4RgWOq7HrxRixHlFlExOLAJr5emLvN7SWXgnLh4+B5xQlNVz8Og8kv
                ArMtNROxVQuCaSnIDdD5LKyWbRd2n9WGe2R8PzgCmr3EgVLrjyBxWezF
                0jLHwVN8efS3rCj/EWgvIWgb9tarpVUDK/b58Da+sqqls3eNbuv7pr+e
                oZG+SrDK6nWeL3c6H5Apxz7LjVc1uTIdsIXxuOLYA4/ilBmSVIzuDWfd
                RUfhHdY6+cn8HFRm+2hM8AnXGXws9555KrUB5qihylGa8subX2Nn6UwN
                R1AkUTV74bU='))

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

        if os_facts[:os]['name'] == 'Debian'
          if os_facts[:os]['release']['major'] == '10'
            it { is_expected.to contain_package('dnsutils').with_ensure('present') }
          else
            it { is_expected.to contain_package('bind9-dnsutils').with_ensure('present') }
          end
        end

        # optional, non-default packages shouldn't be managed by default
        [
          'bind9-dev',
          'bind9-doc',
          'libbind-dev',
          'openresolv',
        ].each do |pkg|
          it { is_expected.not_to contain_package(pkg) }
        end

        it do
          is_expected.to contain_file(File.join(CONFIG_DIR, 'bind.keys')).with(
            ensure: 'file',
            content: root_key,
            validate_cmd: CHECKCONF_CMD,
          )
        end

        default_zone_filenames_to_names.each do |filename, name|
          it do
            is_expected.to contain_file(File.join(CONFIG_DIR, filename)).with(
              ensure: 'file',
              validate_cmd: checkzone_cmd(name),
            )
          end
        end

        if os_facts[:os]['name'] == 'Debian' && os_facts[:os]['release']['major'] == '10'
          it do
            is_expected.to contain_file(File.join(CONFIG_DIR, 'bind.keys')).with(
              ensure: 'file',
              content: %r{managed-keys},
              validate_cmd: CHECKCONF_CMD,
            )
          end
        else
          it do
            is_expected.to contain_file(File.join(CONFIG_DIR, 'bind.keys')).with(
              ensure: 'file',
              content: %r{trust-anchors},
              validate_cmd: CHECKCONF_CMD,
            )
          end
        end

        it do
          is_expected.to contain_file(WORKING_DIR).with(
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
            is_expected.to contain_file(CONFIG_DIR).with(
              ensure: 'directory',
              force: true,
              owner: 'root',
              group: group,
              mode: '2755',
              purge: true,
              recurse: true,
            )
          end

          it { is_expected.to contain_concat(CONFIG_FILE).with_validate_cmd(CHECKCONF_CMD) }

          it do
            is_expected.to contain_concat__fragment('named.conf base')
              .with_content(%r{# Managed by Puppet})
              .with_content(default_zones)
              .with_content(root_hint_zone)
              .without_content(%r{include ".*";})
              .with_order('01')
          end

          it do
            is_expected.to contain_file(File.join(CONFIG_DIR, 'rndc.key')).with(
              ensure: 'file',
              owner: 'root',
              group: group,
              mode: '0640',
              validate_cmd: CHECKCONF_CMD,
            )
          end

          it do
            is_expected.to contain_exec('/usr/sbin/rndc-confgen -a')
              .with_creates(File.join(CONFIG_DIR, 'rndc.key'))
          end
        end

        if os_facts[:os]['family'] == 'Debian'
          it do
            is_expected.to contain_concat__fragment('named.conf base')
              .with_content(%r{directory "#{WORKING_DIR}";}o)
          end

          it { is_expected.to contain_file(File.join('/etc', 'default', service_name)).with_ensure('absent') }
        end

        it do
          is_expected.to contain_systemd__dropin_file("#{service_name}.conf").with(
            unit: "#{service_name}.service",
            notify: ["Service[#{service_name}]"],
            # FIXME: why does this fail?
            # content: <<~CONTENT
            #   # Managed by Puppet
            #   [Service]
            #   Type=simple
            #   EnvironmentFile=
            #   ExecStart=
            #   ExecStart=/usr/sbin/named -f -u #{user} -c '#{CONFIG_FILE}'
            # CONTENT
          )
        end
      end

      context 'authoritative server' do
        let(:params) do
          {
            authoritative: true,
          }
        end

        it { is_expected.to compile.with_all_deps }

        # dnsruby build dependencies
        if os_facts[:os]['name'] == 'Debian'
          [
            'g++',
            'make',
          ].each do |pkg|
            it do
              is_expected.to contain_package(pkg).with(
                ensure: 'present',
                before: 'Package[dnsruby]',
              )
            end
          end
        end

        # workaround for https://github.com/rvm/rvm/issues/4975
        it do
          is_expected.to contain_file('/usr/bin/mkdir').with(
            ensure: 'link',
            target: '/bin/mkdir',
            before: 'Package[dnsruby]',
          )
        end

        it do
          is_expected.to contain_package('dnsruby').with(
            ensure: 'present',
            provider: 'puppet_gem',
          )
        end
      end

      context 'with dev packages' do
        let(:params) do
          {
            dev_packages_ensure: 'installed',
          }
        end

        raise "test not implemented for #{os}, please update" unless os_facts[:os]['name'] == 'Debian'

        it { is_expected.to compile.with_all_deps }

        if os_facts[:os]['name'] == 'Debian' && os_facts[:os]['release']['major'] == '10'
          it { is_expected.to contain_package('libbind-dev').with_ensure('present') }
        else
          it { is_expected.to contain_package('bind9-dev').with_ensure('present') }
        end
      end

      context 'with doc packages' do
        let(:params) do
          {
            doc_packages_ensure: 'installed',
          }
        end

        raise "test not implemented for #{os}, please update" unless os_facts[:os]['name'] == 'Debian'
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('bind9-doc').with_ensure('present') }
      end

      context 'with custom dev_packages' do
        let(:params) do
          {
            dev_packages: ['pkg1', 'pkg2'],
            dev_packages_ensure: 'installed',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('pkg1').with_ensure('present') }
        it { is_expected.to contain_package('pkg2').with_ensure('present') }
      end

      context 'with custom doc_packages' do
        let(:params) do
          {
            doc_packages: ['pkg1', 'pkg2'],
            doc_packages_ensure: 'installed',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('pkg1').with_ensure('present') }
        it { is_expected.to contain_package('pkg2').with_ensure('present') }
      end

      context 'with custom utils_packages' do
        let(:params) do
          {
            utils_packages: ['pkg1', 'pkg2'],
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('pkg1').with_ensure('present') }
        it { is_expected.to contain_package('pkg2').with_ensure('present') }
      end

      context 'without utils packages' do
        let(:params) do
          {
            utils_packages_ensure: 'absent',
          }
        end

        raise "test not implemented for #{os}, please update" unless os_facts[:os]['name'] == 'Debian'

        it { is_expected.to compile.with_all_deps }

        if os_facts[:os]['name'] == 'Debian'
          if os_facts[:os]['release']['major'] == '10'
            it { is_expected.to contain_package('dnsutils').with_ensure('absent') }
          else
            it { is_expected.to contain_package('bind9-dnsutils').with_ensure('absent') }
          end
        end
      end

      context 'without root hint zone' do
        let(:params) do
          {
            root_hint_zone: false,
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_concat__fragment('named.conf base')
            .without_content(root_hint_zone)
        end
      end

      context 'without default zones' do
        let(:params) do
          {
            default_zones: false,
            root_hint_zone: false,
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_concat__fragment('named.conf base')
            .without_content(%r{^zone})
        end

        it { is_expected.not_to contain_file(File.join(CONFIG_DIR, 'db.0')) }
        it { is_expected.not_to contain_file(File.join(CONFIG_DIR, 'db.127')) }
        it { is_expected.not_to contain_file(File.join(CONFIG_DIR, 'db.255')) }
        it { is_expected.not_to contain_file(File.join(CONFIG_DIR, 'db.local')) }
      end

      context 'with custom includes' do
        context 'undef' do
          let(:params) do
            {
              includes: :undef,
            }
          end

          it { is_expected.to compile.with_all_deps }

          it do
            is_expected.to contain_concat__fragment('named.conf base')
              .without_content(%r{include})
          end
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
            is_expected.to contain_concat__fragment('named.conf base')
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
            is_expected.to contain_concat__fragment('named.conf base')
              .with_content(%r{^include "#{custom_includes_array[0]}";$})
              .with_content(%r{^include "#{custom_includes_array[1]}";$})
          end
        end
      end

      context 'with custom zones' do
        let(:params) do
          {
            authoritative: true,
            zones: {
              '.': {
                type: 'mirror',
              },
              'example.com.': {
                manage: true,
                type: 'primary',
                update_policy: ['local'],
                resource_records: {
                  www: {
                    type: 'AAAA',
                    data: '2001:db8::1',
                  },
                },
              },
              'example.net.': {
                type: 'secondary',
              },
            },
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_bind__zone('.') }
        it { is_expected.to contain_bind__zone('example.com.') }
        it { is_expected.to contain_bind__zone('example.net.') }

        context 'with invalid configurations' do
          context 'such as zone name not ending with a dot' do
            let(:params) do
              {
                authoritative: true,
                zones: {
                  'not-ending-with-dot.example.com': {
                    manage: true,
                    type: 'primary',
                  },
                },
              }
            end

            it { is_expected.to compile.and_raise_error(%r{parameter 'zone_name' expects a match}) }
          end

          context 'such as multiple SOA records' do
            let(:params) do
              {
                authoritative: true,
                zones: {
                  'multiple-soa-records.example.com.': {
                    manage: true,
                    type: 'primary',
                    update_policy: ['local'],
                    resource_records: {
                      '@ SOA1': {
                        type: 'SOA',
                        data: 'ns1 hostmaster 2021012401 24h 2h 1000h 1h',
                      },
                      '@ SOA2': {
                        type: 'soa',
                        data: 'ns1 hostmaster 2021012402 24h 2h 1000h 1h',
                      },
                    },
                  },
                },
              }
            end

            it { is_expected.to compile.and_raise_error(%r{only one SOA record allowed per zone}) }
          end

          context 'such as missing type and in-view' do
            let(:params) do
              {
                zones: {
                  'missing-type.example.com.': { update_policy: ['local'] },
                },
              }
            end

            it { is_expected.to compile.and_raise_error(%r{must specify either in-view or type}) }
          end

          context 'such as non-updatable primary zones' do
            let(:params) do
              {
                authoritative: true,
                zones: {
                  'non-updatable.example.com.': {
                    manage: true,
                    type: 'primary',
                    resource_records: {
                      '@ SOA': {
                        type: 'SOA',
                        data: 'ns1 hostmaster 2021010201 24h 2h 1000h 1h',
                      },
                    },
                  },
                },
              }
            end

            it do
              is_expected.to compile.and_raise_error(
                %r{must be updatable locally via allow-update or update-policy},
              )
            end
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
            is_expected.to contain_concat__fragment('named.conf base')
              .with_content(Regexp.new(Regexp.escape(<<~CONTENT)))
                logging {
                    category security {
                        my_security_channel;
                        default_syslog;
                    };
                    category notify {
                        null;
                    };
                };
                CONTENT
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
            is_expected.to contain_concat__fragment('named.conf base')
              .with_content(Regexp.new(Regexp.escape(<<~CONTENT)))
                logging {
                    channel chan1 {
                        null;
                    };
                    channel chan2 {
                        file "log";
                    };
                };
                CONTENT
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
            is_expected.to contain_concat__fragment('named.conf base')
              .with_content(Regexp.new(Regexp.escape(<<~CONTENT)))
                logging {
                    category rpz {
                    };
                    category queries {
                        my_query_channel;
                        default_syslog;
                    };
                    category query-errors {
                        null;
                    };
                    channel an_example_channel {
                        buffered yes;
                        file "example.log" versions unlimited size 100M suffix timestamp;
                        print-category yes;
                        print-time iso8601-utc;
                        severity debug 3;
                    };
                    channel my_query_channel {
                        file "query.log" versions 2 size 1m;
                        print-time true;
                        severity info;
                    };
                };
                CONTENT
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
          is_expected.to contain_concat__fragment('named.conf base')
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
            is_expected.to contain_concat__fragment('named.conf base')
              .with_content(%r{directory "#{WORKING_DIR}"}o)
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

        it do
          is_expected.to contain_systemd__dropin_file("#{service_name}.conf").with(
            unit: "#{service_name}.service",
            notify: ["Service[#{service_name}]"],
            # FIXME: why does this fail?
            # content: <<~CONTENT
            #   # Managed by Puppet
            #   [Service]
            #   Type=simple
            #   EnvironmentFile=
            #   ExecStart=
            #   ExecStart=/usr/sbin/named -f -u #{user} -c '#{CONFIG_FILE}' #{custom_service_options}
            # CONTENT
          )
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
        it { is_expected.to contain_concat(File.join(custom_config_dir, CONFIG_FILENAME)) }
      end

      context 'with a custom service_config_file' do
        custom_service_config_file = '/myconfig'
        let(:params) do
          {
            service_config_file: custom_service_config_file,
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_concat(custom_service_config_file).with(
            validate_cmd: CHECKCONF_CMD,
          )
        end

        it do
          is_expected.to contain_systemd__dropin_file("#{service_name}.conf").with(
            unit: "#{service_name}.service",
            notify: ["Service[#{service_name}]"],
            # FIXME: why does this fail?
            # content: <<~CONTENT
            #   # Managed by Puppet
            #   [Service]
            #   Type=simple
            #   EnvironmentFile=
            #   ExecStart=
            #   ExecStart=/usr/sbin/named -f -u #{user} -c '#{custom_service_config_file}'
            # CONTENT
          )
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

        it do
          is_expected.to contain_systemd__dropin_file("#{service_name}.conf").with(
            unit: "#{service_name}.service",
            notify: ["Service[#{service_name}]"],
            # FIXME: why does this fail?
            # content: <<~CONTENT
            #   # Managed by Puppet
            #   [Service]
            #   Type=simple
            #   EnvironmentFile=
            #   ExecStart=
            #   ExecStart=/usr/sbin/named -f -u #{custom_service_user} -c '#{CONFIG_FILE}'
            # CONTENT
          )
        end

        it do
          is_expected.to contain_file(WORKING_DIR).with(
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
          ).with_ensure('installed')
        end

        it do
          is_expected.to contain_package('bind9-dnsutils').with_install_options(
            ['--target-release', "#{facts[:os]['distro']['codename']}-backports"],
          ).with_ensure('present')
        end

        it { is_expected.not_to contain_package('dnsutils') }
        it { is_expected.to contain_file(File.join(CONFIG_DIR, 'bind.keys')).with_content(%r{trust-anchors}) }

        context 'with dev packages' do
          let(:params) do
            super().merge(dev_packages_ensure: 'installed')
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_package('libbind-dev') }

          it do
            is_expected.to contain_package('bind9-dev').with_install_options(
              ['--target-release', "#{facts[:os]['distro']['codename']}-backports"],
            ).with_ensure('present')
          end
        end
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
          is_expected.to contain_systemd__dropin_file("#{service_name}.conf").with(
            ensure: 'absent',
            unit: "#{service_name}.service",
          )
        end

        it do
          is_expected.to contain_service(service_name).with(
            ensure: 'stopped',
            enable: false,
          )
        end
      end

      context 'with custom keys' do
        let(:params) do
          {
            keys: {
              'key1': {
                algorithm: 'hmac-sha256',
                secret: 'yHqINVuege3zW3EOebA8pnWzpMkpCpMi0f4RqrV4poU=',
              },
              'key2': {
                algorithm: 'hmac-sha512',
                secret: '+2BboRCD6wsbAmqXs2lcg7RzkG3gCN6CgP0oI7FRudJh70JSFmyytOUld+jezwH7tyYgv3B89y18A2AMev+HQQ==',
              },
            },
          }
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_bind__key('key1') }
        it { is_expected.to contain_bind__key('key2') }
      end
    end
  end
end
