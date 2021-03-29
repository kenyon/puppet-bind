# frozen_string_literal: true

require 'puppet/resource_api'

Puppet::ResourceApi.register_type(
  name: 'resource_record',
  docs: <<~EOS,
          @summary a DNS resource record type
          @example AAAA record in the example.com. zone
            resource_record { 'foo.example.com.':
              ensure => 'present',
              type   => 'AAAA',
              data   => '2001:db8::1',
            }

          This type provides Puppet with the capabilities to manage DNS resource records.

          **Autorequires**: If Puppet is managing the zone that this resource record belongs to,
          the resource record will autorequire the zone.
        EOS
  features: ['canonicalize'],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this resource record should be present or absent on the target system.',
      default: 'present',
    },
    record: {
      type: 'String',
      desc: 'The name of the resource record, also known as the owner or label.',
      behavior: :namevar,
    },
    zone: {
      type: 'String',
      desc: 'The zone the resource record belongs to.',
    },
    type: {
      type: 'String',
      desc: 'The type of the resource record.',
    },
    data: {
      type: 'String',
      desc: 'The data for the resource record.',
    },
    ttl: {
      type: 'Optional[Variant[Integer, String]]',
      desc: 'The TTL for the resource record.',
    },
  },
  autorequire: {
    'bind::zone': '$zone',
  },
)
