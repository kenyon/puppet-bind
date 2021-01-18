# frozen_string_literal: true

# SPDX-License-Identifier: AGPL-3.0-or-later

require 'spec_helper'

describe 'Bind::ZoneConfig::UpdatePolicy::Rule' do
  it { is_expected.not_to allow_value(:undef, 12, 'str') }
  it { is_expected.not_to allow_value(permission: 'wrong', identity: 'example.com', ruletype: 'external') }
  it { is_expected.to allow_value(permission: 'grant', identity: 'local-ddns', ruletype: 'zonesub', types: 'any') }

  it do
    is_expected.to allow_value(
      permission: 'deny',
      identity: 'host-key',
      ruletype: 'name',
      name: 'ns1.example.com.',
      types: 'AAAA',
    )
  end

  it { is_expected.to allow_value(permission: 'grant', identity: '*', ruletype: 'tcp-self', name: '.', types: 'PTR(1)') }
end
