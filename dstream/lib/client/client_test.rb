require 'rubygems'
require 'eventmachine'
require 'optparse'
require 'mongrel'
require File.dirname(__FILE__)+'/client'
require File.dirname(__FILE__)+'/client_file_service'
require File.dirname(__FILE__)+'/../common/common_init'

common_init("dstream_client")

# Implementation of a ruby test client for the pdtp protocol
class TestClientProtocol < PDTPProtocol

  def initialize *args
    super
  end

  # Called after a connection to the server has been established
  def connection_completed
    begin
      listen_port=@@config[:listen_port]

      #create the client
      client=Client.new
      PDTPProtocol::listener=client
      client.server_connection=self
      client.my_id=Client::generate_client_id(listen_port)
      client.file_service = ClientFileService.new

      # Start a mongrel server on the specified port.  If it isnt available, keep trying higher ports
      begin
        mongrel_server=Mongrel::HttpServer.new("0.0.0.0",listen_port)
      rescue Exception=>e
        listen_port+=1
        retry
      end

      @@log.info("listening on port #{listen_port}")
      mongrel_server.register("/",client)
      mongrel_server.run

      # Tell the server about ourself
      request={
        "type"=>"client_info",
        "listen_port"=>listen_port,
        "client_id"=>client.my_id
      }
      send_message(request)
      
      # Ask the server for some information on the file we want
      request={
      	"type"=>"ask_info",
	"url"=>@@config[:request_url]
      }
      send_message(request)
      
      # Request the file
      request = {
        "type"=>"request",
        "url"=>@@config[:request_url]
      }
      send_message(request)

      @@log.info("This client is requesting")
    rescue Exception=>e
      puts "Exception in connection_completed: #{e}"
      puts e.backtrace.join("\n")
      exit
    end
    
  end  

  def unbind
    super
    puts "Disconnected from PDTP server. "
    
  end
    
end

# Main test client loop
EventMachine::run {
  host,port,listen_port = @@config[:host],@@config[:port],@@config[:listen_port]
  connection=EventMachine::connect host,port,TestClientProtocol
  @@log.info("connecting with ev=#{EventMachine::VERSION}")
  @@log.info("host= #{host}  port=#{port}") 
}


