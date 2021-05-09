# frozen_string_literal: true

# SPDX-License-Identifier: AGPL-3.0-or-later

require 'spec_helper'

describe 'bind::key' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'generate tsig key' do
        let(:title) { 'sample' }
        let(:params) do
          {
            algorithm: 'hmac-sha512',
            secret: 'ZlfCDgP7d3g7LjV4YMLg62EbpLZRCt9BMh3MyqiZfPX5Y2IcTyx/la6PMsfAqLMM9QDadZiNiLVzD4IPoI/4hg==',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_concat__fragment("key-#{title}").with(
            target: CONFIG_FILE,
            content: <<~CONTENT,
              key "#{title}" {
                  algorithm #{params[:algorithm]};
                  secret "#{params[:secret]}";
              };
            CONTENT
          )
        end
      end
    end
  end
end
