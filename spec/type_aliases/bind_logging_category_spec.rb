# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

require 'spec_helper'

describe 'Bind::Logging::Category' do
  it { is_expected.not_to allow_value(:undef, 12, 'nonexistent-category') }

  it do
    is_expected.to allow_value(
      'client',
      'cname',
      'config',
      'database',
      'default',
      'delegation-only',
      'dispatch',
      'dnssec',
      'dnstap',
      'edns-disabled',
      'general',
      'lame-servers',
      'network',
      'notify',
      'nsid',
      'queries',
      'query-errors',
      'rate-limit',
      'resolver',
      'rpz',
      'rpz-passthru',
      'security',
      'serve-stale',
      'spill',
      'trust-anchor-telemetry',
      'unmatched',
      'update',
      'update-security',
      'xfer-in',
      'xfer-out',
      'zoneload',
    )
  end
end
