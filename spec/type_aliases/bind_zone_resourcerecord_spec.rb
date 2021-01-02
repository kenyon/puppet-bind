# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

require 'spec_helper'

describe 'Bind::Zone::ResourceRecord' do
  it { is_expected.not_to allow_value(:undef, 12, 'str') }

  it do
    is_expected.to allow_value(
      type: 'SOA',
      data: 'ns1 hostmaster (2021010101 24h 2h 1000h 1h)',
    )
  end

  it do
    is_expected.to allow_value(
      'name' => 'www',
      'class' => 'IN',
      'ttl' => '1d',
      'type' => 'AAAA',
      'data' => ['2001:db8::1', '2001:db8::2'],
    )
  end
end
