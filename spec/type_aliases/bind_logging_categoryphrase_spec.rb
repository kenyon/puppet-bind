# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

require 'spec_helper'

describe 'Bind::Logging::CategoryPhrase' do
  it { is_expected.not_to allow_value(:undef, 12, 'string', {}, [], [''], [1], true, wrong: ['s']) }
  it { is_expected.to allow_value(channels: ['array', 'of', 'strings']) }
end
