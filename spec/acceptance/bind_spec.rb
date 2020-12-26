require 'spec_helper_acceptance'

describe 'bind' do
  context 'when using defaults' do
    let(:pp) do
      <<-MANIFEST
        include bind
      MANIFEST
    end

    it_behaves_like 'an idempotent resource after the initial run'

    describe package(PACKAGE_NAME) do
      it { is_expected.to be_installed }
    end

    describe service(SERVICE_NAME) do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end

    it_behaves_like 'a DNS server'
  end

  context 'when stopping the service' do
    let(:pp) do
      <<-MANIFEST
        class { 'bind':
          service_ensure => stopped,
        }
      MANIFEST
    end

    it_behaves_like 'an idempotent resource'

    describe service(SERVICE_NAME) do
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

    it_behaves_like 'an idempotent resource'

    describe service(SERVICE_NAME) do
      it { is_expected.not_to be_enabled }
    end
  end

  context 'when uninstalling' do
    let(:pp) do
      <<-MANIFEST
        class { 'bind':
          package_ensure => absent,
        }
      MANIFEST
    end

    it_behaves_like 'an idempotent resource'

    describe package(PACKAGE_NAME) do
      it { is_expected.not_to be_installed }
    end

    describe service(SERVICE_NAME) do
      it { is_expected.not_to be_enabled }
      it { is_expected.not_to be_running }
    end
  end
end
