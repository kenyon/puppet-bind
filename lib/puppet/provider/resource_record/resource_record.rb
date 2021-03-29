# frozen_string_literal: true

# A Puppet run that executes resource_record code before the dnsruby gem has been installed will
# fail. This code here allows us to ignore such an error to allow the gem to be installed.
begin
  require 'dnsruby'
rescue LoadError # rubocop:disable Lint/SuppressedException
end

require 'puppet/resource_api/simple_provider'

# Implementation for the resource_record type using the Resource API.
class Puppet::Provider::ResourceRecord::ResourceRecord < Puppet::ResourceApi::SimpleProvider
  def get(_context)
    # FIXME: this runs once per resource_record
    system('rndc', 'dumpdb', '-zones')
    zr = Dnsruby::ZoneReader.new(origin: '.')
    records = []
    # FIXME: this filename could be different, configurable in named.conf options dump-file
    zr.process_file('/var/cache/bind/named_dump.db').each do |rr|
      pp rr
      records << {
        title: "#{rr.name} #{rr.type} #{rr.rdata}",
        ensure: 'present',
        record: rr.name.to_s,
        # FIXME: zone name is not always everything after the first dot. need to do more complex
        # parsing of the dump file to get actual zone names.
        zone: rr.name.to_s.split('.')[1..-1].join('.'),
        type: rr.type.to_s,
        data: rr.rdata,
        ttl: rr.ttl.to_s,
      }
    end
    records
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
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
