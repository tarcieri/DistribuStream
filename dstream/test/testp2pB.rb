require 'rubygems'
require 'eventmachine'
require File.dirname(__FILE__)+'/../lib/client/client_message_translator'
require File.dirname(__FILE__)+'/../lib/client/client'
require File.dirname(__FILE__)+'/../lib/client/client_file_service'

#Create a new client and client file service
client=Client.new
client.file_service=ClientFileService.new
PDTPProtocol::listener=client

#Set up file to request
url="pdtp://bla.com/test.txt"
chunkID=1
size=1

EventMachine::run {
  #Connect with server
  host, serverPort="localhost",6005
  serverConnection=EventMachine::connect host,serverPort,PDTPProtocol
  puts "connecting with ev=#{EventMachine::VERSION}"

  #Connection with peer
  host, peerPort="localhost", 6001

  #Create client as server in p2p transfer
  EventMachine::start_server host, peerPort, PDTPProtocol
  peerConnection=EventMachine::connect host, peerPort, PDTPProtocol

  #Create request to ask server about desired file
  request={
    "type"=>"ask_info",
    "url"=>url
  }

  #Set initial state
  state=:give

  #Request info from server
  serverConnection.send_message(request)

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
        serverConnection.send_message(request)
      end
    when :give
      puts "give state"
      puts "accepting connections with ev=#{EventMachine::VERSION}"
    when :take
      puts "take state"
      request={"type"=>"take","chunk_range"=>1..1,"url"=>url}
      peerConnection.send_message(request)
      puts "connecting with ev=#{EventMachine::VERSION}"
    when :completed
      puts "completed transfer"
      request={"type"=>"completed", "url"=>url, "chunkID"=>1}
      serverConnection.send_message(request)
      state=:done
    when :done
      puts "done"
    end
    #puts client.file_service.get_info(url).inspect
  end

}

puts "outside of block"


