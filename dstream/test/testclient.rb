require 'rubygems'
require 'eventmachine'
require File.dirname(__FILE__)+'/../lib/client/client_message_translator'
require File.dirname(__FILE__)+'/../lib/client/client'
require File.dirname(__FILE__)+'/../lib/client/client_file_service'

client=Client.new
client.file_service=ClientFileService.new
PDTPProtocol::listener=client

host="localhost"
port=6000
port=ARGV[0].to_i if ARGV[0]
url="pdtp://bla.com/test.txt"

providing= (ARGV[1] == "p" ) 


EventMachine::run {
  connection=EventMachine::connect host,port,PDTPProtocol
  puts "connecting with ev=#{EventMachine::VERSION}"
  puts "host= #{host}  port=#{port}"

  #puts connection.inspect
  if !providing then 
    request={
     "type"=>"ask_info",
     "url"=>url
    }

    state=:start

    connection.send_message(request)
  else
    request={
      "type"=>"provide",
      "url"=>url,
      "chunk_range"=>0..0
    }
    connection.send_message(request)
    state=:nothing
  end
  

  EventMachine::add_periodic_timer(1) do
    case state
    when :start
      if client.file_service.get_info(url) != nil then
        state=:request_sent
        request={
          "type"=>"request",
          "chunk_range"=> 0..1,
          "url"=> url
        }
        connection.send_message(request)
      end
    end
    #puts client.file_service.get_info(url).inspect
  end

}

puts "outside of block"


