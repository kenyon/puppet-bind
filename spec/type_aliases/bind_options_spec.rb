# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

require 'spec_helper'

describe 'Bind::Options' do
  it { is_expected.not_to allow_value(directory: 'not_absolute') }
  it { is_expected.not_to allow_value('zone-statistics' => 'invalid') }
  it { is_expected.not_to allow_value('allow-query' => 'not_an_array') }

  it do
    is_expected.to allow_value(
      'allow-query' => [
        'localhost',
        'localnets',
        '2001:db8::/32',
        '192.0.2.0/24',
      ],
      'directory' => '/meh',
      'zone-statistics' => 'full',
    )
  end
end
