require 'rubygems'
require 'eventmachine'
require File.dirname(__FILE__)+'/../lib/server/server_message_translator'
require File.dirname(__FILE__)+'/../lib/server/server'
require File.dirname(__FILE__)+'/../lib/server/server_file_service'



server=Server.new
server.file_service=ServerFileService.new
ServerMessageTranslator::server=server

#set root directory
root=File.dirname(__FILE__)+'/../../testfiles'
server.file_service.root=root

EventMachine::run {
  host,port="localhost", 6000
  EventMachine::start_server host,port,ServerMessageTranslator
  puts "accepting connections with ev=#{EventMachine::VERSION}"
  EventMachine::add_periodic_timer(1) { PDTPProtocol::print_info }
}

