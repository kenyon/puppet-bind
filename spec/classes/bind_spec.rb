# frozen_string_literal: true

require 'spec_helper'

config_dir = File.join('/etc', 'bind')
package_name = 'bind9'

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
          is_expected.to contain_service(service_name).with(
            ensure: 'running',
            enable: true,
          )
        end
        it { is_expected.to contain_file(File.join(config_dir, 'named.conf.options')) }
        it { is_expected.to contain_file(File.join('/etc', 'default', service_name)) }
      end

      context 'with resolvconf_service_enable => true', if: os_facts[:os]['name'] == 'Debian' do
        let(:params) do
          {
            resolvconf_service_enable: true,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(File.join('/etc', 'default', service_name)).with_content(%r{RESOLVCONF=yes})
        end
        it { is_expected.to contain_package('openresolv').that_comes_before("Package[#{package_name}]") }
        it do
          is_expected.to contain_service("#{service_name}-resolvconf").with(
            ensure: 'running',
            enable: true,
            require: 'Package[openresolv]',
          )
        end

        context 'with a custom resolvconf_package_name' do
          let(:params) do
            super().merge(resolvconf_package_name: 'myresolvconf')
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_package('myresolvconf').that_comes_before("Package[#{package_name}]") }
          it { is_expected.to contain_service("#{service_name}-resolvconf").with_require('Package[myresolvconf]') }
        end
      end

      context 'with a custom config_dir' do
        let(:params) do
          {
            config_dir: File.join('/etc', 'blag'),
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(File.join('/etc', 'blag', 'named.conf.options')) }
      end

      context 'with a custom package name' do
        let(:params) do
          {
            package_name: 'quux',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('quux') }
      end

      context 'with a custom service name' do
        let(:params) do
          {
            service_name: 'quuz',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_service('quuz') }
      end

      context 'with package_backport => true', if: os_facts[:os]['name'] == 'Debian' do
        let(:params) do
          {
            package_backport: true,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('apt::backports').that_comes_before('Class[bind::install]') }
        it do
          is_expected.to contain_package(package_name).with_install_options(
            ['--target-release', "#{facts[:os]['distro']['codename']}-backports"],
          )
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
          is_expected.to contain_service(service_name).with(
            ensure: 'stopped',
            enable: false,
          )
        end
      end
    end
  end
end
