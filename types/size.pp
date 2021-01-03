# @summary Type definition for BIND's file size specification
#
# Reference: `size_spec` under https://bind9.readthedocs.io/en/latest/reference.html#configuration-file-elements
#
type Bind::Size = Variant[
  Enum['unlimited', 'default'],
  Integer[0],
  Pattern[/\A\d+(?i:k|m|g)\Z/],
]
