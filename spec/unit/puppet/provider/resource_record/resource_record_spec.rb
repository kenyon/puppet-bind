# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::ResourceRecord')
require 'puppet/provider/resource_record/resource_record'

RSpec.describe Puppet::Provider::ResourceRecord::ResourceRecord do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  describe '#get' do
    it 'processes resources' do
      expect(context).to receive(:debug).with('Returning pre-canned example data')
      expect(provider.get(context)).to eq [
        {
          name: 'foo',
          ensure: 'present',
        },
        {
          name: 'bar',
          ensure: 'present',
        },
      ]
    end
  end

  describe 'create(context, name, should)' do
    it 'creates the resource' do
      expect(context).to receive(:notice).with(%r{\ACreating 'a'})

      provider.create(context, 'a', name: 'a', ensure: 'present')
    end
  end

  describe 'update(context, name, should)' do
    it 'updates the resource' do
      expect(context).to receive(:notice).with(%r{\AUpdating 'foo'})

      provider.update(context, 'foo', name: 'foo', ensure: 'present')
    end
  end

  describe 'delete(context, name)' do
    it 'deletes the resource' do
      expect(context).to receive(:notice).with(%r{\ADeleting 'foo'})

      provider.delete(context, 'foo')
    end
  end

  describe 'canonicalize(_context, resources)' do
    it 'upcases/downcases resource attributes' do
      expect(provider.canonicalize(context, [{
        ensure: 'present',
        record: 'wWw',
        zone: 'EXAMPLE.com.',
        type: 'aaaa',
        data: '2001:db8::1',
      }])).to eq([{
        ensure: 'present',
        record: 'www',
        zone: 'example.com.',
        type: 'AAAA',
        data: '2001:db8::1',
      }])
    end
  end
end
