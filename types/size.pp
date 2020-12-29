# @summary Type definition for BIND's file size specification
type Bind::Size = Variant[
  Enum['unlimited', 'default'],
  Integer[0],
  Pattern[/\A\d+(?i:k|m|g)\Z/],
]
