# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

require 'spec_helper'

config_dir = File.join('/etc', 'bind')
config_filename = 'named.conf'
config_file = File.join(config_dir, config_filename)
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
        it { is_expected.to contain_file(File.join(config_dir, 'bind.keys')).with_content(root_key) }
        it { is_expected.to contain_file(File.join(config_dir, 'db.0')) }
        it { is_expected.to contain_file(File.join(config_dir, 'db.127')) }
        it { is_expected.to contain_file(File.join(config_dir, 'db.255')) }
        it { is_expected.to contain_file(File.join(config_dir, 'db.empty')) }
        it { is_expected.to contain_file(File.join(config_dir, 'db.local')) }

        if os_facts[:os]['name'] == 'Debian' && os_facts[:os]['release']['major'] == '10'
          it { is_expected.to contain_file(File.join(config_dir, 'bind.keys')).with_content(%r{managed-keys}) }
        else
          it { is_expected.to contain_file(File.join(config_dir, 'bind.keys')).with_content(%r{trust-anchors}) }
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
            pending 'TODO: implement management of everything'
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
            is_expected.to contain_tidy(config_dir).with(
              matches: 'named.conf.*',
              recurse: true,
            )
          end

          it do
            is_expected.to contain_file(config_file)
              .with_content(%r{# Managed by Puppet})
              .with_content(default_zones)
              .without_content(%r{include ".*";})
          end
        end

        if os_facts[:os]['family'] == 'Debian'
          it do
            is_expected.to contain_file(config_file).with_content(%r{directory "#{working_dir}";})
          end

          it do
            is_expected.to contain_file(
              File.join('/etc', 'default', service_name),
            ).with_content(%r{RESOLVCONF=no})
              .with_content(%r{OPTIONS="-u '#{user}' -c '#{config_file}' "})
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
        it { is_expected.not_to contain_file(File.join(config_dir, 'db.empty')) }
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
              .with_content(%r{include "#{custom_includes_file}";})
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
              .with_content(%r{include "#{custom_includes_array[0]}";})
              .with_content(%r{include "#{custom_includes_array[1]}";})
          end
        end
      end

      context 'with custom options' do
        let(:params) do
          {
            options: {
              'allow-query' => [
                'localhost',
                'localnets',
                '2001:db8::/32',
                '192.0.2.0/24',
              ],
              'directory' => '/meh',
              # PDK's super old rubocop fails to parse this using newer hash syntax :(
              'zone-statistics' => 'full',
            },
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_file(config_file)
            .with_content(%r{directory "/meh";})
            .with_content(%r{zone-statistics full;})
            .with_content(%r<allow-query \{
        localhost;
        localnets;
        2001:db8::/32;
        192\.0\.2\.0/24;
    \};>)
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
            ).with_content(%r{OPTIONS="-u '#{user}' -c '#{config_file}' #{custom_service_options}"})
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
          ).with_content(%r{RESOLVCONF=yes})
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
            ).with_content(%r{OPTIONS="-u '#{user}' -c '#{custom_service_config_file}' "})
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
            ).with_content(%r{OPTIONS="-u '#{custom_service_user}' -c '#{config_file}' "})
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
