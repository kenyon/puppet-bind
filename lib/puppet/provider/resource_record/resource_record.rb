# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'ipaddr'
# Implementation for the resource_record type using the Resource API.
class Puppet::Provider::ResourceRecord::ResourceRecord < Puppet::ResourceApi::SimpleProvider
  def initialize
    super()
    system('rndc', 'dumpdb', '-zones')
    Puppet.debug('Parsing dump for existing resource records...')
    @records = []
    @heldptr = []
    currentzone = ''
    # FIXME: location varies based on config/OS
    unless File.exist?('/var/cache/bind/named_dump.db')
      raise Puppet::Error, 'The named dump file does not exist in the expected location, cannot continue.'
    end
    File.readlines('/var/cache/bind/named_dump.db').each do |line|
      if line[0] == ';' && line.length > 18
        currentzone = line[%r{(?:.*?')(.*?)\/}, 1]
        if currentzone.respond_to?(:to_str); currentzone = currentzone.downcase end
        # Puppet.debug("current zone updated: #{currentzone}")
      elsif line[0] != ';'
        line = line.strip.split(' ', 5)
        rr = {}
        rr[:label] = line[0]
        if rr[:label].respond_to?(:to_str); rr[:label] = rr[:label].downcase end
        # Puppet.debug("----New RR---- label: #{rr[:label]}")
        rr[:ttl] = line[1]
        # Puppet.debug("RR TTL: #{rr[:ttl]}")
        rr[:scope] = line[2]
        # Puppet.debug("RR scope: #{rr[:scope]}")
        rr[:type] = line[3]
        # Puppet.debug("RR type: #{rr[:type]}")
        rr[:data] = if line[4].respond_to?(:to_str)
                      line[4].tr('\"', '')
                    else
                      line[4]
                    end
        # context.debug("RR data: #{rr[:data]}")
        rr[:zone] = currentzone + '.'
        # context.debug("RR zone: #{rr[:zone]}")
        @records << {
          title: "#{rr[:label]} #{rr[:zone]} #{rr[:type]} #{rr[:data]}",
          ensure: 'present',
          record: rr[:label].to_s,
          zone:   rr[:zone].to_s,
          type:   rr[:type].to_s,
          data:   rr[:data].to_s,
          ttl:    rr[:ttl].to_s,
        }
      end
    end
    # context.debug("#{records.inspect}")
  end

  def get(_context)
    @records
  end

  def create(context, name, should)
    context.notice("Creating '#{name}' with #{should.inspect}")

    # I dislike having to send an individual nsupdate for each record, it'd be preferable to
    # build a request for each managed zone on run, append all records we
    # need to act on, then send a bulk nsupdate for each zone - this would require a legacy provider's flush operation
    cmd = if should[:type] == 'TXT'
            "echo 'zone #{should[:zone]}
             update add #{should[:record]} #{should[:ttl]} #{should[:type]} \"#{should[:data]}\"
             send
             quit
             ' | nsupdate -4 -l"
          else
            "echo 'zone #{should[:zone]}
            update add #{should[:record]} #{should[:ttl]} #{should[:type]} #{should[:data]}
            send
            quit
            ' | nsupdate -4 -l"
          end
    system(cmd)

    # FIXME: This will generate PTR records, but assumes the arpa zones are preexisting.
    if (should[:type] == 'A') && !(@heldptr.key? should[:record])
      if should[:holdptr] == 'true'
        @heldptr[should[:record]] = should[:holdptr]
      end
      fqdn = should[:record]
      if fqdn[fqdn.length - 1] != '.'
        fqdn += should[:zone]
      end
      reverse = IPAddr.new(should[:data]).reverse
      cmd = "echo 'update delete #{reverse} PTR
      update add #{reverse} #{should[:ttl]} PTR #{fqdn}
      send
      quit
      ' | nsupdate -4 -l"
      system(cmd)
    end
    @records << {
      title: "#{should[:record]} #{should[:zone]} #{should[:type]} #{should[:data]}",
      ensure: 'present',
      record: should[:record].to_s,
      zone:   should[:zone].to_s,
      type:   should[:type].to_s,
      data:   should[:data].to_s,
      ttl:    should[:ttl].to_s,
    }
  end

  def update(context, name, should)
    context.notice("Updating '#{name.inspect}' with #{should.inspect}")
    cmd = if should[:type] == 'TXT'
            "echo 'zone #{should[:zone]}
            update delete #{name[:record]} #{name[:type]} #{name[:data]}
            update add #{should[:record]} #{should[:ttl]} #{should[:type]} \"#{should[:data]}\"
            send
            quit
            ' | nsupdate -4 -l"
          else
            "echo 'zone #{should[:zone]}
            update delete #{name[:record]} #{name[:type]} #{name[:data]}
            update add #{should[:record]} #{should[:ttl]} #{should[:type]} #{should[:data]}
            send
            quit
            ' | nsupdate -4 -l"
          end
    system(cmd)
    if (should[:type] == 'A') && !(@heldptr.key? should[:record])
      if should[:holdptr] == 'true'
        @heldptr[should[:record]] = should[:holdptr]
      end
      fqdn = should[:record]
      if fqdn[fqdn.length - 1] != '.'
        fqdn += should[:zone]
      end
      reverse = IPAddr.new(should[:data]).reverse
      context.debug("fqdn: #{fqdn}")
      context.debug("reverse: #{reverse}")
      cmd = "echo 'update delete #{reverse} PTR
      update add #{reverse} #{should[:ttl]} PTR #{fqdn}
      send
      quit
      ' | nsupdate -4 -l"
      system(cmd)
    end
    @records.reject! { |rr| rr[:title] == "#{name[:record]} #{name[:zone]} #{name[:type]} #{name[:data]}" }
    @records << {
      title: "#{should[:record]} #{should[:zone]} #{should[:type]} #{should[:data]}",
      ensure: 'present',
      record: should[:record].to_s,
      zone:   should[:zone].to_s,
      type:   should[:type].to_s,
      data:   should[:data].to_s,
      ttl:    should[:ttl].to_s,
    }
  end

  def delete(context, name)
    context.notice("Deleting '#{name}'")
    cmd = "echo 'zone #{name[:zone]}
    update delete #{name[:record]} #{name[:type]} #{name[:data]}
    send
    quit
    ' | nsupdate -4 -l"
    system(cmd)
    @records.reject! { |rr| rr[:title] == "#{name[:record]} #{name[:zone]} #{name[:type]} #{name[:data]}" }
  end

  def canonicalize(context, resources)
    resources.each do |r|
      context.debug(r.inspect)
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
