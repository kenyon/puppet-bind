# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

CONFIG_DIR = File.join('/etc', 'bind').freeze
PACKAGE_NAME = 'bind9'
SERVICE_NAME =
  if os[:family] == 'debian' && os[:release].to_i == 10
    'bind9'
  else
    'named'
  end
WORKING_DIR = File.join('/var', 'cache', 'bind').freeze

shared_examples 'a DNS server' do
  describe port(53) do
    it { is_expected.to be_listening.with 'tcp' }
    it { is_expected.to be_listening.with 'udp' }
  end
end

# The initial installation can't be idempotent because the named.conf.* files don't exist until
# after the package is installed, so Puppet can't see that it needs to remove them with the tidy
# resource until the second run. Subsequent runs should be idempotent though.
shared_examples 'an idempotent resource after the initial run' do
  it 'applies initially' do
    apply_manifest(pp)
  end

  it 'applies idempotently' do
    idempotent_apply(pp)
  end
end

shared_examples 'an idempotent resource' do
  it 'applies idempotently' do
    idempotent_apply(pp)
  end
end
