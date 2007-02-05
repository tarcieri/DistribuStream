require 'rubygems'
require 'eventmachine'
require File.dirname(__FILE__)+'/../lib/client/client_message_translator'
require File.dirname(__FILE__)+'/../lib/client/client'
require File.dirname(__FILE__)+'/../lib/client/client_file_service'
require File.dirname(__FILE__)+'/../lib/server/server_file_service'

client=Client.new
cfs=client.file_service=ClientFileService.new
PDTPProtocol::listener=client

host="localhost"
port=6000
port=ARGV[0].to_i if ARGV[0]
url="pdtp://bla.com/test.txt"

providing= (ARGV[1] == "p" ) 


EventMachine::run {
  connection=EventMachine::connect host,port,PDTPProtocol
  client.server_connection=connection
  puts "connecting with ev=#{EventMachine::VERSION}"
  puts "host= #{host}  port=#{port}"

  listen_port=8000
  begin
    #puts "trying port: #{listen_port}"
    peer_connection=EventMachine::start_server host,listen_port,PDTPProtocol
  rescue
    listen_port+=1
    retry
  end

  puts "listening on port #{listen_port}"
  request={
    "type"=>"change_port",
    "port"=>listen_port
  }
  connection.send_message(request)

  #puts connection.inspect
  if !providing then 
    request={
     "type"=>"ask_info",
     "url"=>url
    }

    state=:start

    connection.send_message(request)
  else
    sfs=ServerFileService.new
    sfs.root=File.dirname(__FILE__)+'/../../testfiles'
    cfs.set_info(url,sfs.get_info(url))
    cfs.set_chunk_data(url,0,sfs.get_chunk_data(url,0))

    request={
      "type"=>"provide",
      "url"=>url,
      "chunk_range"=>0..0
    }
    connection.send_message(request)
    state=:nothing
  end
  

  EventMachine::add_periodic_timer(1) do
    client.print_stats
    case state
    when :start
      if client.file_service.get_info(url) != nil then
        state=:request_sent
        request={
          "type"=>"request",
          "chunk_range"=> 0..0,
          "url"=> url
        }
        connection.send_message(request)
      end
    end
    #puts client.file_service.get_info(url).inspect
  end

}

puts "outside of block"


