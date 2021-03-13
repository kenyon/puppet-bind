# frozen_string_literal: true

require 'spec_helper'

describe 'bind::zone' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'root mirror' do
        let(:title) { '.' }
        let(:params) do
          {
            type: 'mirror',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_concat__fragment(title).with(
            target: CONFIG_FILE,
            content: <<~CONTENT,
              zone "#{title}" {
                  type #{params[:type]};
                  file "db.root";
              };
            CONTENT
          )
        end
      end

      context 'without resource records' do
        let(:title) { 'example.com.' }

        context 'in-view with class' do
          let(:params) do
            {
              class: 'IN',
              in_view: 'view0',
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_file(File.join(WORKING_DIR, "db.#{title}")) }

          it do
            is_expected.to contain_concat__fragment(title).with(
              target: CONFIG_FILE,
              content: <<~CONTENT,
                zone "#{title}" IN {
                    in-view "#{params[:in_view]}";
                };
              CONTENT
            )
          end
        end

        context 'type primary' do
          let(:params) do
            {
              type: 'primary',
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_file(File.join(WORKING_DIR, "db.#{title}")) }

          context 'minimal' do
            it do
              is_expected.to contain_concat__fragment(title).with(
                target: CONFIG_FILE,
                content: <<~CONTENT,
                  zone "#{title}" {
                      type #{params[:type]};
                      file "db.#{title}";
                  };
                CONTENT
              )
            end
          end

          context 'more settings' do
            let(:params) do
              super().merge(
                allow_transfer: ['2001:db8::/64'],
                allow_update: ['2001:db8:2::/64'],
                also_notify: ['2001:db8:1::/64'],
                auto_dnssec: 'maintain',
                file: 'specified-file-example',
                inline_signing: true,
                key_directory: 'example',
              )
            end

            it do
              is_expected.to contain_concat__fragment(title).with(
                target: CONFIG_FILE,
                content: <<~CONTENT,
                  zone "#{title}" {
                      type #{params[:type]};
                      file "#{params[:file]}";
                      allow-transfer {
                          2001:db8::/64;
                      };
                      allow-update {
                          2001:db8:2::/64;
                      };
                      also-notify {
                          2001:db8:1::/64;
                      };
                      auto-dnssec #{params[:auto_dnssec]};
                      inline-signing #{params[:inline_signing]};
                      key-directory "#{params[:key_directory]}";
                  };
                CONTENT
              )
            end
          end

          context 'with update-policy local' do
            let(:params) do
              super().merge(
                update_policy: ['local'],
              )
            end

            it do
              is_expected.to contain_concat__fragment(title).with(
                target: CONFIG_FILE,
                content: <<~CONTENT,
                  zone "#{title}" {
                      type #{params[:type]};
                      file "db.#{title}";
                      update-policy local;
                  };
                CONTENT
              )
            end
          end

          context 'with complex update-policy' do
            let(:params) do
              super().merge(
                update_policy: [
                  permission: 'deny',
                  identity: 'host-key',
                  ruletype: 'name',
                  name: 'ns1.example.com.',
                  types: 'A',
                ],
              )
            end

            it do
              is_expected.to contain_concat__fragment(title).with(
                target: CONFIG_FILE,
                content: <<~CONTENT,
                  zone "#{title}" {
                      type #{params[:type]};
                      file "db.#{title}";
                      update-policy {
                          deny host-key name ns1.example.com. A;
                      };
                  };
                CONTENT
              )
            end
          end

          context 'with complex and local update-policy' do
            let(:params) do
              super().merge(
                update_policy: [
                  'local',
                  {
                    permission: 'deny',
                    identity: 'host-key',
                    ruletype: 'name',
                    name: 'ns1.example.com.',
                  },
                ],
              )
            end

            it do
              is_expected.to contain_concat__fragment(title).with(
                target: CONFIG_FILE,
                content: <<~CONTENT,
                  zone "#{title}" {
                      type #{params[:type]};
                      file "db.#{title}";
                      update-policy local;
                      update-policy {
                          deny host-key name ns1.example.com. ;
                      };
                  };
                CONTENT
              )
            end
          end

          context 'with complex update-policy and serial-update-method' do
            let(:params) do
              super().merge(
                update_policy: [
                  permission: 'grant',
                  identity: 'local-ddns',
                  ruletype: 'zonesub',
                  types: 'any',
                ],
                serial_update_method: 'unixtime',
              )
            end

            it do
              is_expected.to contain_concat__fragment(title).with(
                target: CONFIG_FILE,
                content: <<~CONTENT,
                  zone "#{title}" {
                      type #{params[:type]};
                      file "db.#{title}";
                      serial-update-method unixtime;
                      update-policy {
                          grant local-ddns zonesub  any;
                      };
                  };
                CONTENT
              )
            end
          end
        end

        context 'type secondary' do
          let(:params) do
            {
              type: 'secondary',
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.not_to contain_file(File.join(WORKING_DIR, "db.#{title}")) }

          context 'with primaries' do
            let(:params) do
              super().merge(
                primaries: ['2001:db8::1'],
              )
            end

            it do
              is_expected.to contain_concat__fragment(title).with(
                target: CONFIG_FILE,
                content: <<~CONTENT,
                  zone "#{title}" {
                      type #{params[:type]};
                      file "db.#{title}";
                      primaries {
                          2001:db8::1;
                      };
                  };
                CONTENT
              )
            end
          end

          context 'forward' do
            let(:params) do
              super().merge(
                forward: 'only',
                forwarders: ['192.0.2.3', '192.0.2.4'],
              )
            end

            it do
              is_expected.to contain_concat__fragment(title).with(
                target: CONFIG_FILE,
                content: <<~CONTENT,
                  zone "#{title}" {
                      type #{params[:type]};
                      file "db.#{title}";
                      forward #{params[:forward]};
                      forwarders {
                          192.0.2.3;
                          192.0.2.4;
                      };
                  };
                CONTENT
              )
            end
          end
        end
      end

      context 'with resource records' do
        let(:facts) do
          super().merge(
            networking: {
              hostname: 'ns1',
              ip: '192.0.2.1',
              ip6: '2001:db8::1',
            },
          )
        end

        let(:node) { 'ns1.example.com' }

        let(:params) do
          {
            type: 'primary',
            update_policy: ['local'],
          }
        end

        let(:title) { 'example.com.' }

        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_concat__fragment(title).with(
            target: CONFIG_FILE,
            content: <<~CONTENT,
              zone "#{title}" {
                  type #{params[:type]};
                  file "db.#{title}";
                  update-policy local;
              };
            CONTENT
          )
        end

        context 'with default SOA values and default NS records' do
          let(:params) do
            super().merge(
              resource_records: {
                www: {
                  type: 'AAAA',
                  data: '2001:db8::2',
                },
              },
            )
          end

          it do
            is_expected.to contain_file(File.join(WORKING_DIR, "db.#{title}")).with(
              ensure: 'file',
              owner: USER,
              replace: false,
              validate_cmd: checkzone_cmd(title),
              content: <<~CONTENT,
                $TTL 2d
                @  SOA #{facts[:networking][:hostname]} hostmaster 1 24h 2h 1000h 1h
                @ NS #{facts[:networking][:hostname]}
                #{facts[:networking][:hostname]} AAAA #{facts[:networking][:ip6]}
                #{facts[:networking][:hostname]} A #{facts[:networking][:ip]}
              CONTENT
            )
          end

          it do
            is_expected.to contain_resource_record('www').with(
              zone: title,
              type: params[:resource_records][:www][:type],
              data: params[:resource_records][:www][:data],
            )
          end
        end

        context 'with non-default SOA and default NS records' do
          let(:params) do
            super().merge(
              ttl: '4d',
              resource_records: {
                soa: {
                  type: 'SOA',
                  ttl: '8d',
                  data: "#{facts[:networking][:hostname]} hostmaster 2021010201 48h 6h 1500h 2h",
                },
              },
            )
          end

          it do
            is_expected.to contain_file(File.join(WORKING_DIR, "db.#{title}")).with(
              ensure: 'file',
              owner: USER,
              replace: false,
              validate_cmd: checkzone_cmd(title),
              content: <<~CONTENT,
                $TTL 4d
                @ 8d SOA #{facts[:networking][:hostname]} hostmaster 2021010201 48h 6h 1500h 2h
                @ NS #{facts[:networking][:hostname]}
                #{facts[:networking][:hostname]} AAAA #{facts[:networking][:ip6]}
                #{facts[:networking][:hostname]} A #{facts[:networking][:ip]}
              CONTENT
            )
          end
        end

        context 'with non-default SOA and non-default NS records' do
          context 'IPv6 only' do
            let(:facts) do
              super().merge(
                networking: {
                  ip: nil,
                },
              )
            end

            context 'single address' do
              let(:params) do
                super().merge(
                  resource_records: {
                    soa: {
                      type: 'SOA',
                      data: 'my-ns hostmaster 2021010301 48h 6h 1500h 30m',
                    },
                    ns: {
                      name: 'my-ns',
                      type: 'AAAA',
                      data: '2001:db8::ffff',
                    },
                  },
                )
              end

              it do
                is_expected.to contain_file(File.join(WORKING_DIR, "db.#{title}")).with(
                  ensure: 'file',
                  owner: USER,
                  replace: false,
                  validate_cmd: checkzone_cmd(title),
                  content: <<~CONTENT,
                    $TTL 2d
                    @  SOA my-ns hostmaster 2021010301 48h 6h 1500h 30m
                    @ NS my-ns
                    my-ns AAAA 2001:db8::ffff
                  CONTENT
                )
              end
            end

            context 'array' do
              let(:params) do
                super().merge(
                  resource_records: {
                    soa: {
                      type: 'SOA',
                      data: 'my-ns hostmaster 2021010301 48h 6h 1500h 30m',
                    },
                    ns: {
                      name: 'my-ns',
                      type: 'AAAA',
                      data: [
                        '2001:db8::eeee',
                        '2001:db8::ffff',
                      ],
                    },
                  },
                )
              end

              it do
                is_expected.to contain_file(File.join(WORKING_DIR, "db.#{title}")).with(
                  ensure: 'file',
                  owner: USER,
                  replace: false,
                  validate_cmd: checkzone_cmd(title),
                  content: <<~CONTENT,
                    $TTL 2d
                    @  SOA my-ns hostmaster 2021010301 48h 6h 1500h 30m
                    @ NS my-ns
                    my-ns AAAA 2001:db8::eeee
                    my-ns AAAA 2001:db8::ffff
                  CONTENT
                )
              end
            end
          end

          context 'legacy only' do
            let(:facts) do
              super().merge(
                networking: {
                  ip6: nil,
                },
              )
            end

            context 'single address' do
              let(:params) do
                super().merge(
                  resource_records: {
                    soa: {
                      type: 'SOA',
                      data: 'my-ns hostmaster 2021010301 48h 6h 1500h 30m',
                    },
                    ns: {
                      name: 'my-ns',
                      type: 'A',
                      data: '192.0.2.254',
                    },
                  },
                )
              end

              it do
                is_expected.to contain_file(File.join(WORKING_DIR, "db.#{title}")).with(
                  ensure: 'file',
                  owner: USER,
                  replace: false,
                  validate_cmd: checkzone_cmd(title),
                  content: <<~CONTENT,
                    $TTL 2d
                    @  SOA my-ns hostmaster 2021010301 48h 6h 1500h 30m
                    @ NS my-ns
                    my-ns A 192.0.2.254
                  CONTENT
                )
              end
            end

            context 'array' do
              let(:params) do
                super().merge(
                  resource_records: {
                    soa: {
                      type: 'SOA',
                      data: 'my-ns hostmaster 2021010301 48h 6h 1500h 30m',
                    },
                    ns: {
                      name: 'my-ns',
                      type: 'A',
                      data: [
                        '192.0.2.253',
                        '192.0.2.254',
                      ],
                    },
                  },
                )
              end

              it do
                is_expected.to contain_file(File.join(WORKING_DIR, "db.#{title}")).with(
                  ensure: 'file',
                  owner: USER,
                  replace: false,
                  validate_cmd: checkzone_cmd(title),
                  content: <<~CONTENT,
                    $TTL 2d
                    @  SOA my-ns hostmaster 2021010301 48h 6h 1500h 30m
                    @ NS my-ns
                    my-ns A 192.0.2.253
                    my-ns A 192.0.2.254
                  CONTENT
                )
              end
            end
          end

          context 'legacy and IPv6' do
            let(:params) do
              super().merge(
                resource_records: {
                  soa: {
                    type: 'SOA',
                    data: 'my-ns hostmaster 2021010301 48h 6h 1500h 30m',
                  },
                  ns: {
                    name: 'my-ns',
                    type: 'AAAA',
                    data: '2001:db8::ffff',
                  },
                  ns_legacy: {
                    name: 'my-ns',
                    type: 'A',
                    data: '192.0.2.254',
                  },
                },
              )
            end

            it do
              is_expected.to contain_file(File.join(WORKING_DIR, "db.#{title}")).with(
                ensure: 'file',
                owner: USER,
                replace: false,
                validate_cmd: checkzone_cmd(title),
                content: <<~CONTENT,
                  $TTL 2d
                  @  SOA my-ns hostmaster 2021010301 48h 6h 1500h 30m
                  @ NS my-ns
                  my-ns AAAA 2001:db8::ffff
                  my-ns A 192.0.2.254
                CONTENT
              )
            end
          end
        end
      end
    end
  end
end
