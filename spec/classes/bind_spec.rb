# frozen_string_literal: true

require 'spec_helper'

config_dir = File.join('/etc', 'bind')
package_name = 'bind9'

describe 'bind' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      service_name =
        if os_facts[:os]['name'] == 'Debian' && os_facts[:os]['release']['major'].to_i == 10
          'bind9'
        else
          'named'
        end

      context 'using defaults' do
        it { is_expected.to compile }
        it { is_expected.to contain_package(package_name).with_ensure('installed') }
        it do
          is_expected.to contain_service(service_name).with(
            ensure: 'running',
            enable: true,
            require: "Package[#{package_name}]",
          )
        end
        it { is_expected.to contain_file(File.join(config_dir, 'named.conf.options')) }
      end

      context 'with a custom package name' do
        let(:params) do
          {
            package_name: 'quux',
          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_package('quux') }
      end

      context 'with a custom service name' do
        let(:params) do
          {
            service_name: 'quuz',
          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_service('quuz') }
      end

      context 'with package_backport => true', if: os_facts[:os]['name'] == 'Debian' do
        let(:params) do
          {
            package_backport: true,
          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_class('apt::backports') }
        it do
          is_expected.to contain_package(package_name).with_install_options(
            ['--target-release', "#{os_facts[:os]['distro']['codename']}-backports"],
          )
        end
      end

      context 'when manage_package => false' do
        let(:params) do
          {
            manage_package: false,
          }
        end

        it { is_expected.not_to contain_package(package_name) }
        it { is_expected.to contain_service(service_name).without_require }
      end

      context 'when manage_service => false' do
        let(:params) do
          {
            manage_service: false,
          }
        end

        it { is_expected.not_to contain_service(service_name) }
      end

      context 'when uninstalled' do
        let(:params) do
          {
            package_ensure: 'absent',
          }
        end

        it { is_expected.to compile }
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
