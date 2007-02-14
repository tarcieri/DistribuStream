require 'rubygems'
require 'eventmachine'
require 'optparse'
require 'logger'
require File.dirname(__FILE__)+'/../lib/server/server'
require File.dirname(__FILE__)+'/../lib/server/server_file_service'
require File.dirname(__FILE__)+'/../lib/common/pdtp_protocol'
require File.dirname(__FILE__)+'/../lib/server/server_config'

@@config=ServerConfig.instance

OptionParser.new do |opts|
	opts.banner = "Usage: testserver.rb [options]"
	opts.on("--log LOGFILE", "Use specified logfile") do |l|
	  @@config.log = l
	end
	opts.on("--host HOST", "Start server on specified host") do |h|
		@@config.host = h
	end
	opts.on("--port PORT", "Listen on specified port") do |q|
	  @@config.port = q.to_i
	end
	opts.on("--file-root ROOT", "Directory where files may be found") do |r|
		@@config.file_root = r
	end
	opts.on("-d","Turn on debugging") do |d|
	  @@config.debug = d
	end
	opts.on("-f","Emulate firewall") do |f|
	  @@config.firewall = f
	end
	opts.on_tail("-h","--help","Print this message") do
		puts opts
		exit
	end
end.parse!

@@log=Logger.new(@@config.log)
@@log.level=Logger::DEBUG
@@log.datetime_format=""


server=Server.new
server.file_service=ServerFileService.new
PDTPProtocol::listener=server

#set root directory
server.file_service.root=@@config.file_root

EventMachine::run {
	host,port=@@config.host, @@config.port
  EventMachine::start_server host,port,PDTPProtocol
  @@log.info("accepting connections with ev=#{EventMachine::VERSION}")
  @@log.info("host=#{host}  port=#{port}")
}

