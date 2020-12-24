# frozen_string_literal: true

PACKAGE_NAME = 'bind9'.freeze
SERVICE_NAME =
  if os[:family] == 'debian' && os[:release].to_i == 10
    'bind9'.freeze
  else
    'named'.freeze
  end

shared_examples 'a DNS server' do
  describe port(53) do
    it { is_expected.to be_listening.with 'tcp' }
    it { is_expected.to be_listening.with 'udp' }
  end
end
