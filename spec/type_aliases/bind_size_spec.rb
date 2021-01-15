# frozen_string_literal: true

# SPDX-License-Identifier: AGPL-3.0-or-later

require 'spec_helper'

describe 'Bind::Size' do
  it { is_expected.not_to allow_value(:undef, [], {}, '', ' ', '1', '1 m', -1, true, false) }
  it { is_expected.to allow_value(0, 1, '1m', '1M', '100G', '10G', '23k', '12K', 'default', 'unlimited') }
end
