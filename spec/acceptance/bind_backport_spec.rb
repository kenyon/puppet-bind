require 'spec_helper_acceptance'

describe 'bind with package_backport => true', if: os[:family] == 'debian' do
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

  it 'applies idempotently' do
    idempotent_apply(pp)
  end

  it 'is installed from backports' do
    run_shell("apt list #{PACKAGE_NAME}") do |shell|
      expect(shell.stdout).to match %r{-backports.*installed.*}
    end
  end

  describe service('named') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  it_behaves_like 'a DNS server'
end
