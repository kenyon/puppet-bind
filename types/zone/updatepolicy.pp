# @summary Type definition for BIND's `update-policy` clause in the `zone` statement
type Bind::Zone::UpdatePolicy = Variant[Enum['local'], Bind::Zone::UpdatePolicy::Rule]
