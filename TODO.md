# To do

- `git grep -E 'TODO|FIXME'`
- manage the entire `/etc/bind` directory
  - replicate the default `db.*` files and associated `zone` statements
- use dynamic zone files for regular user-defined zones
  - use [dnsruby](https://rubygems.org/gems/dnsruby) to do zone updates
    - types and providers with the Resource API
- `named.conf` is a `concat` built by `concat_fragment` resources from the below defined types
  and classes contained by `bind::config`
- create defined types for named.conf statements. Each will have an optional `target` parameter
  for the file to render to, which will default to the main `named.conf`.
  - keys
  - views
  - zones
  - anything else that there can be multiple instances of
- create classes for the singleton config statements (same `target` thing as above):
  - logging
  - options
