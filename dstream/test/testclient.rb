require 'rubygems'
require 'eventmachine'
require File.dirname(__FILE__)+'/../lib/client/client_message_translator'
require File.dirname(__FILE__)+'/../lib/client/client'
require File.dirname(__FILE__)+'/../lib/client/client_file_service'

client=Client.new
client.file_service=ClientFileService.new
ClientMessageTranslator::client=client


EventMachine::run {
  host,port="localhost", 6000
  EventMachine::connect host,port,ClientMessageTranslator
  puts "connecting with ev=#{EventMachine::VERSION}"
  #
  #
  #EventMachine::add_periodic_timer(1) { PDTPProtocol::print_info }
}

