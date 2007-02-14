require 'rubygems'
require 'eventmachine'
require 'optparse'
require 'mongrel'
require File.dirname(__FILE__)+'/../lib/client/client'
require File.dirname(__FILE__)+'/../lib/client/client_file_service'
require File.dirname(__FILE__)+'/../lib/server/server_file_service'
require 'logger'

@@log=Logger.new(STDOUT)
@@log.level= Logger::DEBUG
@@log.datetime_format=""

client=Client.new
cfs=client.file_service=ClientFileService.new
PDTPProtocol::listener=client

OPTIONS = {
	:host => '127.0.0.1',
	:port => 6000,
	:url => 'pdtp://bla.com/test2.txt',
	:listen => 8000,
	:provide => false,
	:root => File.dirname(__FILE__)+'/../../testfiles'
}
OptionParser.new do |opts|
  opts.banner = "Usage: testclient.rb [options]"
	opts.on("--host HOST", "Connect to specified host") do |h|
		OPTIONS[:host] = h
	end
	opts.on("--port PORT", "Connect to specified port") do |p|
		OPTIONS[:port] = p.to_i
	end
	opts.on("--url URL","Request/Provide specified url") do |u|
		OPTIONS[:url] = u
	end
	opts.on("--listen LISTENPORT","Specify first port to attempt to listen on") do |l|
		OPTIONS[:listen] = l.to_i
	end
	opts.on("--file-root ROOT","Directory where files may be found") do |r|
	  OPTIONS[:root] = r
  end
	opts.on_tail("-p","Provide data instead of requesting it") do |p|
		OPTIONS[:provide] = p
	end
	opts.on_tail("-h","--help","Print this message") do 
		puts opts
		exit
	end
end.parse!


EventMachine::run {
	host,port,listen_port = OPTIONS[:host],OPTIONS[:port],OPTIONS[:listen]
	url,providing = OPTIONS[:url], OPTIONS[:provide]
  connection=EventMachine::connect host,port,PDTPProtocol
  client.server_connection=connection
  @@log.info("connecting with ev=#{EventMachine::VERSION}")
  @@log.info("host= #{host}  port=#{port}")

  #start the mongrel server on the specified port.  If it isnt available, keep trying higher ports
  begin
    mongrel_server=Mongrel::HttpServer.new("0.0.0.0",listen_port)
  rescue Exception=>e
    listen_port+=1
    retry
  end

  @@log.info("listening on port #{listen_port}")
  mongrel_server.register("/",client)
  mongrel_server.run

 
  request={
    "type"=>"change_port",
    "port"=>listen_port
  }
  connection.send_message(request)

  if !providing then
    @@log.info("This client is requesting") 
    request={
     "type"=>"ask_info",
     "url"=>url
    }

    state=:start

    connection.send_message(request)
  else
    @@log.info("This client is providing")
    sfs=ServerFileService.new
    sfs.root=OPTIONS[:root]
    #cfs.set_info(url,sfs.get_info(url))
    #cfs.set_chunk_data(url,0,sfs.get_chunk_data(url,0))
    client.file_service=sfs #give this client access to all data

    request={
      "type"=>"provide",
      "url"=>url,
      "chunk_range"=>0..2
    }
    connection.send_message(request)
    state=:nothing
  end
  

  EventMachine::add_periodic_timer(1) do
    #client.print_stats
    case state
    when :start
      if client.file_service.get_info(url) != nil then
        state=:request_sent
        request={
          "type"=>"request",
          "chunk_range"=> 0..2,
          "url"=> url
        }
        connection.send_message(request)
      end
		else
			#client.update_finished_transfers
    end
  end
}



