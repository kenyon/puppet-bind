# @return [String[1]] the name of the BIND service
#
# @api private
#
function bind::service_name() >> String[1] {
  if $bind::package_backport and $facts['os']['release']['major'] == '10' {
    'named'
  } else {
    $bind::service_name
  }
}
