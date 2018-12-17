# frozen_string_literal: true

##############################################################
## DO NOT EDIT THIS FILE                                    ##
## Use /etc/puppetlabs/bolt-server/conf.d/bolt-server.conf  ##
## to configure the sinatra server                          ##
##############################################################

require 'bolt_server/transport_app'
require 'bolt_server/acl'
require 'bolt_server/config'
require 'bolt/logger'

Bolt::Logger.initialize_logging

config_path = ENV['BOLT_SERVER_CONF'] || '/etc/puppetlabs/bolt-server/conf.d/bolt-server.conf'

config = BoltServer::Config.new
config.load_file_config(config_path)
config.load_env_config
config.validate

Logging.logger[:root].add_appenders Logging.appenders.stderr(
  'console',
  layout: Bolt::Logger.default_layout,
  level: config['loglevel']
)

if config['logfile']
  stdout_redirect config['logfile'], config['logfile'], true
end

# TODO: use ssl_bind
bind_addr = +"ssl://#{config['host']}:#{config['port']}?"
bind_addr << "cert=#{config['ssl-cert']}"
bind_addr << "&key=#{config['ssl-key']}"
bind_addr << "&ca=#{config['ssl-ca-cert']}"
bind_addr << "&verify_mode=force_peer"
bind_addr << "&ssl_cipher_filter=#{config['ssl-cipher-suites'].join(':')}"
bind bind_addr

threads 0, config['concurrency']

impl = BoltServer::TransportApp.new(config)
unless config['whitelist'].nil?
  impl = BoltServer::ACL.new(impl, config['whitelist'])
end

app impl
