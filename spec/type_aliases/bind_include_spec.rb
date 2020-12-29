# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

require 'spec_helper'

describe 'Bind::Include' do
  it { is_expected.not_to allow_value(:undef, 12, 'not_absolute_path') }
  it { is_expected.not_to allow_value(['/array', '/of', '/absolute/paths']) }
  it { is_expected.to allow_value('/absolute/path') }
end
