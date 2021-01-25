# frozen_string_literal: true

def checkzone_cmd(zone_name)
  "/usr/sbin/named-checkzone -k fail -m fail -M fail -n fail -r fail -S fail '#{zone_name}' %"
end

CHECKCONF_CMD = '/usr/sbin/named-checkconf %'
CONFIG_DIR = File.join('/etc', 'bind')
CONFIG_FILENAME = 'named.conf'
CONFIG_FILE = File.join(CONFIG_DIR, CONFIG_FILENAME)
USER = 'bind'
WORKING_DIR = File.join('/var', 'cache', 'bind')
