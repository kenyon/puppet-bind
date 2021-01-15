# frozen_string_literal: true

# SPDX-License-Identifier: AGPL-3.0-or-later

require 'spec_helper'

describe 'Bind::Logging::ChannelPhrase' do
  it { is_expected.not_to allow_value(:undef, 12, 'string', [], wrong: true) }
  it { is_expected.not_to allow_value(file: { versions: 3 }) }
  it { is_expected.not_to allow_value(file: { name: 'log', suffix: 'wrong' }) }
  it { is_expected.not_to allow_value(file: { name: 'log', versions: 'wrong' }) }
  it { is_expected.not_to allow_value(syslog: 'wrong') }
  it { is_expected.not_to allow_value(file: { name: 'log', versions: 2.3 }) }
  it { is_expected.not_to allow_value(file: { name: 'log', versions: 0 }) }
  it { is_expected.not_to allow_value(file: { name: 'log', versions: -1 }) }
  it { is_expected.to allow_value(buffered: true) }
  it { is_expected.to allow_value(file: { name: 'log' }) }
  it { is_expected.to allow_value(file: { name: 'log', versions: 3 }) }
  it { is_expected.to allow_value(file: { name: 'log', versions: 'unlimited' }) }
  it { is_expected.to allow_value(file: { name: 'log', size: 12 }) }
  it { is_expected.to allow_value(file: { name: 'log', size: '2m' }) }
  it { is_expected.to allow_value(file: { name: 'log', suffix: 'increment' }) }
  it { is_expected.to allow_value(file: { name: 'log', suffix: 'timestamp' }) }
  it { is_expected.to allow_value('null') }
  it { is_expected.to allow_value('stderr') }
  it { is_expected.to allow_value('syslog') }
  it { is_expected.to allow_value('print-category' => true) }
  it { is_expected.to allow_value('print-severity' => true) }
  it { is_expected.to allow_value({ 'print-time' => true }, 'print-time' => 'iso8601') }
  it { is_expected.to allow_value({ 'print-time' => 'no' }, 'print-time' => 'iso8601-utc') }
  it { is_expected.to allow_value({ 'print-time' => 'yes' }, 'print-time' => 'local') }
  it { is_expected.to allow_value(severity: 'dynamic') }
  it { is_expected.to allow_value(syslog: 'daemon') }
end
