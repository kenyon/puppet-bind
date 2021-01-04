# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

require 'spec_helper_acceptance'

describe 'authoritative BIND with zones configured' do
  domain_name = 'test0.example.'

  before(:context) do
    # Needed for testing.
    utilities_install = <<-MANIFEST
      package { 'bind9-host':
        ensure => installed,
      }
    MANIFEST
    apply_manifest(utilities_install)
  end

  let(:pp) do
    <<-MANIFEST
      class { 'bind':
        zones => [
          {
            'name' => '#{domain_name}',
            'type' => 'master',
            'update-policy' => ['local'],
            'resource-records' => [
              {
                'name' => 'www',
                'type' => 'AAAA',
                'data' => '2001:db8::1',
              },
            ],
          },
        ],
      }
    MANIFEST
  end

  it_behaves_like 'an idempotent resource after the initial run'
  it_behaves_like 'a DNS server'

  describe file(File.join(WORKING_DIR, "db.#{domain_name}")) do
    it { is_expected.to be_file }
  end

  describe command("host -t SOA #{domain_name} localhost") do
    its(:exit_status) { is_expected.to eq 0 }
  end

  describe command("host -t AAAA www.#{domain_name} localhost") do
    its(:exit_status) { pending; is_expected.to eq 0 } # rubocop:disable Style/Semicolon
  end
end
