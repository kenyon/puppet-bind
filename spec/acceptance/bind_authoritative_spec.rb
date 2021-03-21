# frozen_string_literal: true

# SPDX-License-Identifier: AGPL-3.0-or-later

require 'spec_helper_acceptance'

describe 'authoritative BIND with zones configured' do
  domain_name = 'test0.example.'

  let(:pp) do
    <<-MANIFEST
      class { 'bind':
        zones => {
          '#{domain_name}' => {
            'type' => 'master',
            'update_policy' => ['local'],
            'resource_records' => {
              'www aaaa' => {
                'data' => '2001:db8::1',
              },
            },
          },
        },
      }

      # test various title_patterns
      resource_record { 'mail.#{domain_name} a':
        data => '192.0.2.1',
        ttl  => '12d',
      }

      resource_record { 'mx.#{domain_name}':
        type => 'mx',
        data => '0 mail',
      }

      resource_record { 'test1':
        type => 'aaaa',
        data => '2001:db8::2',
        zone => '#{domain_name}',
      }

      resource_record { 'test two':
        record => 'test2',
        zone   => '#{domain_name}',
        type   => 'aaaa',
        data   => '2001:db8::3',
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

  # TODO: verify output matches test data, like record types and TTLs
  ['www', 'test1', 'test2'].each do |nombre|
    describe command("host -t AAAA #{nombre}.#{domain_name} localhost") do
      its(:exit_status) { pending; is_expected.to eq 0 } # rubocop:disable Style/Semicolon
    end
  end

  describe command("host -t a mail.#{domain_name} localhost") do
    its(:exit_status) { pending; is_expected.to eq 0 } # rubocop:disable Style/Semicolon
  end

  describe command("host -t mx mx.#{domain_name} localhost") do
    its(:exit_status) { pending; is_expected.to eq 0 } # rubocop:disable Style/Semicolon
  end
end
