require 'rubygems'
require 'eventmachine'
require 'optparse'
require 'logger'
require File.dirname(__FILE__)+'/server'
require File.dirname(__FILE__)+'/server_file_service'
require File.dirname(__FILE__)+'/../common/pdtp_protocol'
require File.dirname(__FILE__)+'/../common/common_init'

require 'mongrel'

common_init("dstream_server")

server=Server.new
server.file_service=ServerFileService.new
PDTPProtocol::listener=server


#set up the mongrel server for serving the stats page
class MongrelServerHandler< Mongrel::HttpHandler
  def initialize(server)
    @server=server
  end

  def process(request,response)
    response.start(200) do |head,out|
      begin
        outstr=@server.generate_html_stats
      rescue Exception=>e
        outstr="Exception: #{e}\n#{e.backtrace.join("\n")}"
      end
      out.write(outstr)
    end    
  end
end

#run the mongrel server
mongrel_server=Mongrel::HttpServer.new("0.0.0.0",@@config[:port]+1)
@@log.info("Mongrel server listening on port: #{@@config[:port]+1}")
mongrel_server.register("/",MongrelServerHandler.new(server))
mongrel_server.run
                        

#set root directory
server.file_service.root=@@config[:file_root]
server.file_service.default_chunk_size = @@config[:chunk_size]

EventMachine::run {
  
	host,port="0.0.0.0", @@config[:port]
  EventMachine::start_server host,port,PDTPProtocol
  @@log.info("accepting connections with ev=#{EventMachine::VERSION}")
  @@log.info("host=#{host}  port=#{port}")

  EventMachine::add_periodic_timer( 2 ) do
    server.clear_all_stalled_transfers 
  end
}

