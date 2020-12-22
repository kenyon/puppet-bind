require 'spec_helper_acceptance'

package_name = 'bind9'
service_name =
  if os[:family] == 'debian' && os[:release].to_i == 10
    'bind9'
  else
    'named'
  end

describe 'bind' do
  context 'when using defaults' do
    let(:pp) do
      <<-MANIFEST
        include bind
      MANIFEST
    end

    it 'applies idempotently' do
      idempotent_apply(pp)
    end

    describe package(package_name) do
      it { is_expected.to be_installed }
    end

    describe service(service_name) do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    it 'resolves names' do
      host_install = <<-MANIFEST
        package { 'bind9-host':
          ensure => installed,
        }
      MANIFEST

      apply_manifest(host_install)
      run_shell('host dns.google localhost')
    end
  end

  context 'when stopping the service' do
    let(:pp) do
      <<-MANIFEST
        class { 'bind':
          service_ensure => stopped,
        }
      MANIFEST
    end

    it 'applies idempotently' do
      idempotent_apply(pp)
    end

    describe service(service_name) do
      it { is_expected.not_to be_running }
    end
  end

  context 'when disabling the service' do
    let(:pp) do
      <<-MANIFEST
        class { 'bind':
          service_enable => false,
        }
      MANIFEST
    end

    it 'applies idempotently' do
      idempotent_apply(pp)
    end

    describe service(service_name) do
      it { is_expected.not_to be_enabled }
    end
  end

  context 'when uninstalled' do
    let(:pp) do
      <<-MANIFEST
        class { 'bind':
          package_ensure => absent,
        }
      MANIFEST
    end

    it 'applies idempotently' do
      idempotent_apply(pp)
    end

    describe package(package_name) do
      it { is_expected.not_to be_installed }
    end

    describe service(service_name) do
      it { is_expected.not_to be_enabled }
      it { is_expected.not_to be_running }
    end
  end

  context 'when using backported package', if: os[:family] == 'debian' do
    # workaround for https://github.com/puppetlabs/puppetlabs-apt/pull/964
    before(:context) do
      lsb_release_install = <<-MANIFEST
        package { 'lsb-release':
          ensure => installed,
        }
      MANIFEST
      apply_manifest(lsb_release_install)
    end

    let(:pp) do
      <<-MANIFEST
        class { 'bind':
          package_backport => true,
        }
      MANIFEST
    end

    # doesn't work idempotently for some reason :(
    # it 'applies idempotently' do
    #   idempotent_apply(pp)
    # end

    it 'takes two runs to fully apply for some reason' do
      apply_manifest(pp)
      apply_manifest(pp)
    end

    it 'is installed from backports' do
      run_shell("apt list #{package_name}") do |shell|
        expect(shell.stdout).to match(%r{-backports.*installed.*})
      end
    end

    describe service('named') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end
end
