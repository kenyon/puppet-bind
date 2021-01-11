# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/resource_record'

RSpec.describe 'the resource_record type' do
  it 'loads' do
    expect(Puppet::Type.type(:resource_record)).not_to be_nil
  end
end
