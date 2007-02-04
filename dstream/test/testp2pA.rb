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
  host, serverPort="localhost", 6005
  serverConnection=EventMachine::connect host, serverPort, PDTPProtocol
  puts "connecting with ev=#{EventMachine::VERSION}"
  puts "host= #{host} port=#{serverPort}"

  #Connection with peer
  host, peerPort="localhost", 6001

  #Create client as client in p2p transfer
  peerConnection=EventMachine::connect host, peerPort, PDTPProtocol

  #Create request to ask server about desired file
  request={
    "type"=>"ask_info",
    "url"=>url
  }

  #Set initial state
  state=:start

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
    when :request_sent
      puts "waiting for response to request"
      state=:take_request
    when :give
      puts "give state"
      puts "accepting connections with ev=#{EventMachine::VERSION}"
    when :take_request
      puts "take request"
      request={"type"=>"take","chunk_range"=>1..1,"url"=>url}
      peerConnection.send_message(request)
      state=:take
    when :take
      puts "taking state"
      puts "connecting with ev=#{EventMachine::VERSION}"
      state=:completed
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


