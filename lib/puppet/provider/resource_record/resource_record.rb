# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'

# Implementation for the resource_record type using the Resource API.
class Puppet::Provider::ResourceRecord::ResourceRecord < Puppet::ResourceApi::SimpleProvider
  def initialize
    system('rndc', 'dumpdb', '-zones')
  end
  def get(context)
    context.notice("Getting existing resource records...")
    
    records = []
    #FIXME: location varies based on config/OS
    File.readlines('/var/cache/bind/named_dump.db').each do |line|
      if line[0] == ';' && line.length > 18
        context.debug("line for zone name: #{line}")
        currentzone = line[/(?:.*?')(.*?)\//,1]
        context.debug("current zone: #{currentzone}") 
      elsif line[0] != ';'
        line = line.strip.split(' ', 5)
        rr = {}
        rr[:label] = line[0]
        rr[:ttl] = line[1]
        rr[:scope] = line[2]
        rr[:type] = line[3]
        rr[:data] = line[4]
        rr[:zone] = currentzone
        records << {
          ensure: 'present',
          record: "#{rr[:label]}",
          zone:   "#{rr[:zone]}",
          type:   "#{rr[:type]}",
          data:   "#{rr[:data]}",
          ttl:    "#{rr[:ttl]}",
        }
      end
    end
    records
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")
    
    #I dislike having to send an individual nsupdate for each record, it'd be preferable to
    #build a request for each managed zone on run, append all records we
    #need to act on, then send a bulk nsupdate for each zone  
     
    #the delete line is temporary to prevent duplicate creations while this is in progress
    cmd = "echo 'zone #{should[:zone]}
    update delete #{should[:record]} #{should[:type]}
    update add #{should[:record]} #{should[:ttl]} #{should[:type]} #{should[:data]}
    send
    ' | nsupdate -l"
    system(cmd)
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
    cmd = "echo 'zone #{should[:zone]}
    update delete #{should[:record]} #{should[:type]}
    update add #{should[:record]} #{should[:ttl]} #{should[:type]} #{should[:data]}
    send
    ' | nsupdate -l"
    system(cmd)
   end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
    cmd = "echo 'zone #{should[:zone]}
    update delete #{should[:record]} #{should[:type]} #{should[:data]}
    send
    ' | nsupdate -l"
    system(cmd)
  end

  def canonicalize(_context, resources)
    resources.each do |r|
      _context.notice("Record: #{r[:record]}")
      #r[:record] = r[:record].downcase
      _context.notice("Zone: #{r[:zone]}")
      #r[:zone] = r[:zone].downcase
      _context.notice("Type: #{r[:type]}")
      #r[:type] = r[:type].upcase
    end
  end
end
