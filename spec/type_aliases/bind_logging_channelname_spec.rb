# frozen_string_literal: true

# SPDX-License-Identifier: AGPL-3.0-or-later

require 'spec_helper'

describe 'Bind::Logging::ChannelName' do
  it { is_expected.not_to allow_value(:undef, 12, {}, [], '', true, false, 'da-sh', '-', 'a b') }
  it { is_expected.to allow_value('channel_name', '_chan_name_') }
end
