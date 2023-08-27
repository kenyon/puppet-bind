# SPDX-License-Identifier: AGPL-3.0-or-later

# @summary Create TSIG key for zone updates in the configuration file for BIND
#
# @see https://bind9.readthedocs.io/en/latest/advanced.html#tsig
#
# @example Add a TSIG key to the nameserver
#   bind::key { 'tsig-client':
#     algorithm => 'hmac-sha512',
#     secret    => 'secret-key-data',
#   }
#
# @param algorithm
#   Defines the algorithm which was used to generate the key data.
#   For security reasons just allow algorithms hmac-sha256 and above:
#   https://www.rfc-editor.org/rfc/rfc8945.html#name-algorithms-and-identifiers
#
# @param secret
#   Provide the secret data of the TSIG key, generated using tsig-keygen.
define bind::key (
  Enum['hmac-sha256', 'hmac-sha384', 'hmac-sha512'] $algorithm,
  String[44] $secret,
) {
  include bind

  concat::fragment { "key-${name}":
    target  => $bind::service_config_file,
    content => epp("${module_name}/key.epp",
      {
        name      => $name,
        algorithm => $algorithm,
        secret    => $secret,
      }
    ),
  }
}
