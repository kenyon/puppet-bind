# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

require 'spec_helper'

describe 'Bind::Zone' do
  it { is_expected.not_to allow_value(:undef, 12, 'string') }
  it { is_expected.not_to allow_value(name: 'not.ending.with.a.dot', file: 'meh') }
  it { is_expected.to allow_value(name: 'example.com.', file: 'not_absolute') }
  it { is_expected.to allow_value('name' => 'example.com.', 'key-directory' => 'not-absolute-dir') }
  it { is_expected.to allow_value(name: 'example.com.', class: 'IN', 'in-view' => 'view1') }
  it { is_expected.to allow_value(name: 'example.com.', class: 'HS', 'in-view' => 'view2') }
  it { is_expected.to allow_value(name: 'example.com.', class: 'CHAOS', 'in-view' => 'view3') }
  it { is_expected.to allow_value(name: 'example.com.', class: 'IN', type: 'primary') }
  it { is_expected.to allow_value(name: 'example.com.', type: 'secondary') }
  it { is_expected.to allow_value(name: 'example.com.', type: 'slave') }
  it { is_expected.to allow_value(name: '.', type: 'mirror') }
  it { is_expected.to allow_value(name: 'example.com.', type: 'hint') }
  it { is_expected.to allow_value(name: 'example.com.', type: 'stub') }
  it { is_expected.to allow_value(name: 'example.com.', type: 'static-stub') }
  it { is_expected.to allow_value(name: 'example.com.', type: 'forward', forward: 'only', forwarders: ['2001:db8::1', 'example.net']) }
  it { is_expected.to allow_value(name: 'example.com.', type: 'forward', forward: 'first', forwarders: ['192.0.2.1']) }
  it { is_expected.to allow_value(name: 'example.com.', type: 'redirect') }
  it { is_expected.to allow_value(name: 'example.com.', type: 'delegation-only') }
  it { is_expected.to allow_value(name: 'example.com.', type: 'secondary', file: '/xyz', primaries: ['2001:db8::2']) }
  it { is_expected.to allow_value(name: 'example.com.', type: 'slave', file: '/xyz', masters: ['2001:db8::2']) }
  it { is_expected.to allow_value('name' => 'example.com.', 'key-directory' => '/absolute-dir') }
  it { is_expected.to allow_value('name' => 'example.com.', 'allow-transfer' => ['2001:db8::/64']) }
  it { is_expected.to allow_value('name' => 'example.com.', 'allow-update' => ['2001:db8:2::/64']) }
  it { is_expected.to allow_value('name' => 'example.com.', 'also-notify' => ['2001:db8:1::/64']) }
  it { is_expected.to allow_value('name' => 'example.com.', 'serial-update-method' => 'unixtime') }

  it do
    is_expected.to allow_value(
      name: 'example.com.',
      type: 'master',
      file: '/z',
      'auto-dnssec' => 'maintain',
      'inline-signing' => true,
    )
  end

  it { is_expected.to allow_value('name' => 'example.com.', 'update-policy' => ['local']) }

  it do
    is_expected.to allow_value(
      'name' => 'example.com.',
      'update-policy' => [
        'local',
        {
          permission: 'grant',
          identity: '*',
          ruletype: 'tcp-self',
          name: '.',
          types: 'PTR(1)',
        },
      ],
    )
  end

  it do
    is_expected.to allow_value(
      'name' => 'example.com.',
      'update-policy' => [
        {
          permission: 'grant',
          identity: '*',
          ruletype: 'tcp-self',
          name: '.',
          types: 'PTR(1)',
        },
      ],
    )
  end
end
