require 'rubygems'
require 'eventmachine'
require 'optparse'
require File.dirname(__FILE__)+'/../lib/server/server_message_translator'
require File.dirname(__FILE__)+'/../lib/server/server'
require File.dirname(__FILE__)+'/../lib/server/server_file_service'


OPTIONS = {
	:host => '127.0.0.1',
	:port => 6000, 
	:firewall => false,
	:root => File.dirname(__FILE__)+'/../../testfiles'
}
OptionParser.new do |opts|
	opts.banner = "Usage: testserver.rb [options]"
	opts.on("--host HOST", "Start server on specified host") do |h|
		OPTIONS[:host] = h
	end
	opts.on("--port PORT", "Listen on specified port") do |q|
	  OPTIONS[:port] = q.to_i
	end
	opts.on("--file-root ROOT", "Directory where files may be found") do |r|
		OPTIONS[:root] = r
	end
	opts.on_tail("-f","Emulate firewall") do |f|
	  OPTIONS[:firewall] = f
	end
	opts.on_tail("-h","--help","Print this message") do
		puts opts
		exit
	end
end.parse!

server=Server.new
server.file_service=ServerFileService.new
PDTPProtocol::listener=server

#set root directory
server.file_service.root=OPTIONS[:root]

EventMachine::run {
	host,port=OPTIONS[:host], OPTIONS[:port]
  EventMachine::start_server host,port,PDTPProtocol
  puts "accepting connections with ev=#{EventMachine::VERSION}"
  puts "host=#{host}  port=#{port}"
  EventMachine::add_periodic_timer(1) { server.print_stats }
}

