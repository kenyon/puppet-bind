# @summary Type definition for rules in BIND's `update-policy` clause in the `zone` statement
type Bind::Zone::UpdatePolicy::Rule = Struct[{
  'permission' => Enum['deny', 'grant'],
  'identity'   => String[1],
  'ruletype'   => Enum[
    'name',
    'subdomain',
    'zonesub',
    'wildcard',
    'self',
    'selfsub',
    'selfwild',
    'ms-self',
    'ms-selfsub',
    'ms-subdomain',
    'krb5-self',
    'krb5-selfsub',
    'krb5-subdomain',
    'tcp-self',
    '6to4-self',
    'external',
  ],
  Optional['name'] => String[1],
  Optional['types'] => String[1],
}]