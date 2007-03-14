require 'rubygems'
require 'eventmachine'
require 'optparse'
require 'mongrel'
require File.dirname(__FILE__)+'/../lib/client/client'
require File.dirname(__FILE__)+'/../lib/client/client_file_service'
require File.dirname(__FILE__)+'/../lib/server/server_file_service'
require 'logger'
require File.dirname(__FILE__)+'/../lib/client/client_config'

client=Client.new
cfs=client.file_service=ClientFileService.new
PDTPProtocol::listener=client

@@config=ClientConfig.instance

OptionParser.new do |opts|
  opts.banner = "Usage: testclient.rb [options]"
	opts.on("--bytestart BYTE", "Use specified starting byte") do |cs|
    @@config.byte_start = cs.to_i
	end
	opts.on("--byteend BYTE", "Use specified ending byte") do |ce|
	  @@config.byte_end = ce.to_i
	end
	opts.on("--log LOGFILE", "Use specified logfile") do |l|
		@@config.log = l
  end
	opts.on("--host HOST", "Connect to specified host") do |h|
		@@config.host = h
	end
	opts.on("--port PORT", "Connect to specified port") do |p|
		@@config.port = p.to_i
	end
	opts.on("--url URL","Request/Provide specified url") do |u|
    @@config.url = u
	end
	opts.on("--listen LISTENPORT","Specify first port to attempt to listen on") do |l|
		@@config.listen_port = l.to_i
	end
	opts.on("--file-root ROOT","Directory where files may be found") do |r|
	  @@config.file_root = r
  end
	opts.on("-p","Provide data instead of requesting it") do |p|
		@@config.provide = p
	end
	opts.on("-d","Turn on debugging") do |d|
	  @@config.debug = d
	end
  opts.on("-q","--quiet", "Be quiet") do |q|
    @@config.debug_level=Logger::INFO if q
  end

	opts.on_tail("-h","--help","Print this message") do 
		puts opts
		exit
	end
end.parse!

@@log=Logger.new(@@config.log)
@@log.level= @@config.debug_level
@@log.datetime_format=""


EventMachine::run {
	host,port,listen_port = @@config.host,@@config.port,@@config.listen_port
	url,providing = @@config.url, @@config.provide
  connection=EventMachine::connect host,port,PDTPProtocol
  client.server_connection=connection
  @@log.info("connecting with ev=#{EventMachine::VERSION}")
  @@log.info("host= #{host}  port=#{port}")

  oldbytes = 0
  points = 1
  avg = 0
  if !@@config.provide then
    EventMachine::add_periodic_timer(1) do
      info=cfs.get_info(@@config.url)
      newbytes = info.bytes_downloaded
      point_rate = newbytes - oldbytes 
      avg += point_rate
      points += 1 unless point_rate == 0 
      avg_rate = avg / points
      oldbytes = newbytes
      puts "Bytes downloaded: #{newbytes}  Point Rate: #{point_rate}  Average Rate: #{avg_rate}" unless info.nil?
    end
  end

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
    connection.send_message(request)
  
	else
    @@log.info("This client is providing")
    sfs=ServerFileService.new
    sfs.root=@@config.file_root
    client.file_service=sfs #give this client access to all data

    request={
      "type"=>"provide",
      "url"=>url
    }
    connection.send_message(request)
  end
}



