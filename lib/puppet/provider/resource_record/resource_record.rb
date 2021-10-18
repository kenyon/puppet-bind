# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'

# Implementation for the resource_record type using the Resource API.
class Puppet::Provider::ResourceRecord::ResourceRecord < Puppet::ResourceApi::SimpleProvider
  def get(context)
    context.debug('Returning pre-canned example data')
    
    #Trigger a dumpdb on agent run and destroy on completion.
    #
    
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
    
    #Temporary measure to make these "just work". This will regenerate every single manually defined 
    #record on each agent run, which is...okay? At a certain point scale makes that less than ideal.
    #I also dislike having to send an individual nsupdate for each record. With the current structure,
    #it'd be preferable to create a /tmp/ file for each managed zone on run, append all records we
    #need to act on, then do an nsupdate for each zone file and subsequently destroy them.  
     
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
    cmd = "echo 'zone #{should[:zone]}
    update delete #{should[:record]} #{should[:type]}
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
