# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'

# Implementation for the resource_record type using the Resource API.
class Puppet::Provider::ResourceRecord::ResourceRecord < Puppet::ResourceApi::SimpleProvider
  def get(context)
    context.debug('Returning pre-canned example data')
    [
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

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
    cmd = "echo 'zone #{should[:zone]}
    update delete #{should[:record]} #{should[:type]}
    update add #{should[:record]} #{should[:ttl]} #{should[:type]} #{should[:data]}
    send
    ' | nsupdate -l"
    system(cmd)
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
  end

  def canonicalize(_context, resources)
    resources.each do |r|
      r[:record] = r[:record].downcase
      r[:zone] = r[:zone].downcase
      r[:type] = r[:type].upcase
    end
  end
end
