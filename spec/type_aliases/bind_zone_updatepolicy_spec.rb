# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

require 'spec_helper'

describe 'Bind::Zone::UpdatePolicy' do
  it { is_expected.not_to allow_value(:undef, 12, 'str', ['str']) }
  it { is_expected.to allow_value('local') }
  it { is_expected.to allow_value(permission: 'grant', identity: '*', ruletype: 'tcp-self', name: '.', types: 'PTR(1)') }
end
