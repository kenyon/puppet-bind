# frozen_string_literal: true

# SPDX-License-Identifier: AGPL-3.0-or-later

require 'spec_helper'

describe 'Bind::Logging' do
  it { is_expected.not_to allow_value(:undef, 12, 'string') }
  it { is_expected.to allow_value(categories: {}) }
  it { is_expected.to allow_value(channels: {}) }
  it { is_expected.to allow_value(channels: {}, categories: {}) }
  it { is_expected.to allow_value(categories: { rpz: {} }) }
  it { is_expected.to allow_value(categories: { notify: { channels: ['ch1', 'ch2'] } }) }
  it { is_expected.to allow_value(channels: { one: 'null' }) }
  it { is_expected.to allow_value(channels: { two: 'stderr' }) }
  it { is_expected.to allow_value(channels: { three: 'syslog' }) }
  it { is_expected.to allow_value(channels: { four: { 'print-category' => true } }) }
  it { is_expected.to allow_value(channels: { five: { 'print-time' => true } }) }
  it { is_expected.to allow_value(channels: { six: { 'print-time' => 'local' } }) }
  it { is_expected.to allow_value(channels: { seven: { 'print-time' => 'yes' } }) }

  it do
    is_expected.to allow_value(
      channels: {
        an_example_channel: {
          buffered: true,
          file: {
            name: 'example.log',
            versions: 'unlimited',
            size: '100M',
            suffix: 'timestamp',
          },
          'print-category' => true,
          'print-time' => 'iso8601-utc',
          severity: 'debug 3',
        },
        my_query_channel: {
          file: {
            name: 'query.log',
            versions: 2,
            size: '1m',
          },
          'print-time' => true,
          severity: 'info',
        },
      },
      categories: {
        rpz: {},
        queries: {
          channels: [
            'my_query_channel',
            'default_syslog',
          ],
        },
        'query-errors' => {
          channels: ['null'],
        },
      },
    )
  end
end
