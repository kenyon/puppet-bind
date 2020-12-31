# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

require 'spec_helper'

describe 'Bind::Options' do
  it { is_expected.not_to allow_value(:undef, 12, 'string') }
  it { is_expected.not_to allow_value(directory: 'not_absolute') }
  it { is_expected.not_to allow_value('zone-statistics' => 'invalid') }
  it { is_expected.not_to allow_value('allow-query' => 'not_an_array') }

  it { is_expected.to allow_value('allow-transfer' => ['2001:db8::/64']) }
  it { is_expected.to allow_value('allow-update' => ['2001:db8:2::/64']) }
  it { is_expected.to allow_value('also-notify' => ['2001:db8:1::/64']) }

  it do
    is_expected.to allow_value(
      'allow-query' => [
        'localhost',
        'localnets',
        '2001:db8::/32',
        '192.0.2.0/24',
      ],
      'directory' => '/meh',
      'zone-statistics' => 'full',
    )
  end

  it { is_expected.to allow_value('auto-dnssec' => 'maintain', 'inline-signing' => true) }
  it { is_expected.to allow_value('key-directory' => 'dir') }
  it { is_expected.to allow_value('serial-update-method' => 'date') }
end
