require 'rubygems'
require 'eventmachine'
require File.dirname(__FILE__)+'/../lib/client/client_message_translator'
require File.dirname(__FILE__)+'/../lib/client/client'
require File.dirname(__FILE__)+'/../lib/client/client_file_service'

client=Client.new
client.file_service=ClientFileService.new
ClientMessageTranslator::client=client

host="localhost"
port=6000
url="pdtp://bla.com/test.txt"

EventMachine::run {
  connection=EventMachine::connect host,port,ClientMessageTranslator
  puts "connecting with ev=#{EventMachine::VERSION}"

  #puts connection.inspect
  request={
    "type"=>"ask_info",
    "url"=>url
  }

  state=:start

  connection.send_message(request)

  EventMachine::add_periodic_timer(1) do
    case state
    when :start
      if client.file_service.get_info(url) != nil then
        state=:request_sent
        request={
          "type"=>"request",
          "chunk_range"=> 1..1,
          "url"=> url
        }
        connection.send_message(request)
      end
    end
    #puts client.file_service.get_info(url).inspect
  end

}

puts "outside of block"


