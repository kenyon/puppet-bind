# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'

# Implementation for the resource_record type using the Resource API.
class Puppet::Provider::ResourceRecord::ResourceRecord < Puppet::ResourceApi::SimpleProvider
  def initialize
    system('rndc', 'dumpdb', '-zones')
  end
  def get(context)
    context.notice("Getting existing resource records...")
    
    #FIXME: Trigger a dumpdb on agent run and destroy on completion instead of every RR operation
    #system('rndc', 'dumpdb', '-zones')
    records = []
    #FIXME: location varies based on config/OS
    File.readlines('/var/cache/bind/named_dump.db').each do |line|
      if line[0] == ';' && line.length > 17
        context.debug("line for zone name: #{line}")
        currentzone = line[/(?:.*?')(.*?)\//,1]
        context.debug("current zone: #{currentzone}") 
      elsif line[0] != ';'
        line = line.strip.split(' ', 5)
        context.debug("get line for parsing: #{line.to_s}")
        rr = {}
        rr[:label] = line[0]
        rr[:ttl] = line[1]
        rr[:scope] = line[2]
        rr[:type] = line[3]
        rr[:data] = line[4]
        rr[:zone] = currentzone
        records << {
          title: "#{rr[:name]} #{rr[:type]} #{rr[:data]}",
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
    
    #Temporary measure to make these "just work". This will regenerate every single manually defined 
    #record on each agent run, which is...okay? At a certain point scale makes that less than ideal.
    #I also dislike having to send an individual nsupdate for each record. With the current structure,
    #it'd be preferable to create a /tmp/ file for each managed zone on run, append all records we
    #need to act on, then do an nsupdate for each zone file and subsequently destroy them.  
     
    cmd = "echo 'zone #{should[:zone]}
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
      r[:record] = r[:record].downcase
      r[:zone] = r[:zone].downcase
      r[:type] = r[:type].upcase
    end
  end
end
