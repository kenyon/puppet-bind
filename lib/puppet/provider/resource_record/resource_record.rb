# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'ipaddr'
# Implementation for the resource_record type using the Resource API.
class Puppet::Provider::ResourceRecord::ResourceRecord < Puppet::ResourceApi::SimpleProvider
  def initialize
    system('rndc', 'dumpdb', '-zones')
  end
  def get(context)
    context.debug("Parsing dump for existing resource records...")
    
    records = []
    currentzone = ""
    #FIXME: location varies based on config/OS
    File.readlines('/var/cache/bind/named_dump.db').each do |line|
      if line[0] == ';' && line.length > 18
        currentzone = line[/(?:.*?')(.*?)\//,1]
        context.debug("current zone updated: #{currentzone}") 
      elsif line[0] != ';'
        line = line.strip.split(' ', 5)
        rr = {}
        rr[:label] = line[0]
        context.debug("----New RR---- label: #{rr[:label]}")
        rr[:ttl] = line[1]
        context.debug("RR TTL: #{rr[:ttl]}")
        rr[:scope] = line[2]
        context.debug("RR scope: #{rr[:scope]}")
        rr[:type] = line[3]
        context.debug("RR type: #{rr[:type]}")
        if line[4].respond_to?(:to_str)
          rr[:data] = line[4].tr('\"', '')
        else
          rr[:data] = line[4]
        end
        context.debug("RR data: #{rr[:data]}")
        rr[:zone] = currentzone + '.'
        context.debug("RR zone: #{rr[:zone]}")
        records << {
          title: "#{rr[:label]} #{rr[:zone]} #{rr[:type]}",
          ensure: 'present',
          record: "#{rr[:label]}",
          zone:   "#{rr[:zone]}",
          type:   "#{rr[:type]}",
          data:   "#{rr[:data]}",
          ttl:    "#{rr[:ttl]}",
        }
      end
    end
    context.debug("#{records.inspect}")
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
    quit
    ' | nsupdate -4 -l"
    system(cmd)
    
    #FIXME: This will generate PTR records, but assumes the arpa zones are preexisting. 
    if should[:type] == "A"
      fqdn = should[:record]
      if fqdn[fqdn.length-1] != "."
        fqdn = fqdn + should[:zone]
      end
      reverse = IPAddr.new(should[:data]).reverse
      cmd = "echo 'update delete #{reverse} PTR
      update add #{reverse} PTR #{fqdn}
      send
      quit
      ' | nsupdate -4 -l"
      system(cmd)
    end
  end

  def update(context, name, should)
    context.notice("Updating '#{name}' with #{should.inspect}")
    context.debug("old: #{name[:record]}")
    context.debug("new: #{should[:record]}")
    cmd = "echo 'zone #{should[:zone]}
    update delete #{name[:record]} #{name[:type]} #{name[:data]}
    update add #{should[:record]} #{should[:ttl]} #{should[:type]} #{should[:data]}
    send
    quit
    ' | nsupdate -4 -l"
    system(cmd)
    if should[:type] == "A"
      fqdn = should[:record]
      if fqdn[fqdn.length-1] != "."
        fqdn = fqdn + should[:zone]
      end
      context.debug("IPs: #{name[:data] should[:data]}")
      reverse_name = IPAddr.new(name[:data]).reverse
      reverse_should = IPAddr.new(should[:data]).reverse
      context.debug("fqdn: #{fqdn}")
      context.debug("reverse_name: #{reverse_name}")
      context.debug("reverse_should: #{reverse_should}")
      cmd = "echo 'update delete #{reverse_name} PTR
      update add #{reverse_should} PTR #{fqdn}
      send
      quit
      ' | nsupdate -4 -l"
      system(cmd)
    end
   end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
    cmd = "echo 'zone #{name[:zone]}
    update delete #{name[:record]} #{name[:type]} #{name[:data]}
    send
    quit
    ' | nsupdate -4 -l"
    system(cmd)
    if name[:type] == "A"
      reverse = IPAddr.new("#{name[:data]}").reverse
      cmd = "echo 'update delete #{reverse} PTR
      send
      quit
      ' | nsupdate -4 -l"
    end
  end

  def canonicalize(_context, resources)
    resources.each do |r|
      
      _context.debug("#{r.inspect}")
      if r[:record].respond_to?(:to_str)
        r[:record] = r[:record].downcase.strip
      end
      if r[:zone].respond_to?(:to_str)
        r[:zone] = r[:zone].downcase
      end
      if r[:type].respond_to?(:to_str) 
        r[:type] = r[:type].upcase
      end
      if r[:data].respond_to?(:to_str)
        r[:data] = r[:data].tr('\"', '')
      end
    end
  end
end
