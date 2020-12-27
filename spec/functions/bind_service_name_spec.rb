# frozen_string_literal: true

# SPDX-License-Identifier: GPL-3.0-or-later

require 'spec_helper'

describe 'bind::service_name' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'default' do
        before(:each) do
          allow(scope).to receive(:lookupvar).with('bind::service_name').and_return('the service name')
          allow(scope).to receive(:lookupvar).with('bind::package_backport').and_return(false)
          allow(scope).to receive(:lookupvar).with('facts').and_return(
            'os' => {
              'name' => 'Debian',
              'release' => {
                'major' => '11',
              },
            },
          )
        end

        it { is_expected.to run.and_return('the service name') }
      end

      context 'on Debian 10 with $bind::package_backport => true' do
        if os_facts[:os]['name'] == 'Debian' && os_facts[:os]['release']['major'] == '10'
          before(:each) do
            allow(scope).to receive(:lookupvar).with('bind::package_backport').and_return(true)
            allow(scope).to receive(:lookupvar).with('facts').and_return(
              'os' => {
                'name' => 'Debian',
                'release' => {
                  'major' => '10',
                },
              },
            )
          end

          it { is_expected.to run.and_return('named') }
        end
      end
    end
  end
end
