# frozen_string_literal: true

# SPDX-License-Identifier: AGPL-3.0-or-later

require 'spec_helper_acceptance'

describe 'bind with resolvconf_service_enable => true', if: os[:family] == 'debian' do
  let(:pp) do
    <<~MANIFEST
      class { 'bind':
        resolvconf_service_enable => true,
      }
    MANIFEST
  end

  it_behaves_like 'an idempotent resource after the initial run'

  describe package('openresolv') do
    it { is_expected.to be_installed }
  end

  describe service("#{SERVICE_NAME}-resolvconf") do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe file(File.join('/etc', 'resolv.conf')) do
    its(:content) { is_expected.to match %r{\A# Generated by resolvconf\nnameserver\s+127\.0\.0\.1\Z} }
  end

  it_behaves_like 'a DNS server'
end
