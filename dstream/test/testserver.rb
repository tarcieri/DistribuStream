require 'rubygems'
require 'eventmachine'
require 'optparse'
require 'logger'
require File.dirname(__FILE__)+'/../lib/server/server'
require File.dirname(__FILE__)+'/../lib/server/server_file_service'
require File.dirname(__FILE__)+'/../lib/common/pdtp_protocol'
require File.dirname(__FILE__)+'/../lib/server/server_config'

require 'mongrel'

@@config=ServerConfig.instance

OptionParser.new do |opts|
	opts.banner = "Usage: testserver.rb [options]"
	opts.on("--chunksize CHUNKSIZE", "Use specified chunk size") do |c|
	  @@config.chunk_size = c.to_i
	end
	opts.on("--log LOGFILE", "Use specified logfile") do |l|
	  @@config.log = l
	end
	opts.on("--host HOST", "Start server on specified host") do |h|
		@@config.host = h
	end
	opts.on("--port PORT", "Listen on specified port") do |q|
	  @@config.port = q.to_i
	end
	opts.on("--file-root ROOT", "Directory where files may be found") do |r|
		@@config.file_root = r
	end
	opts.on("-d","Turn on debugging") do |d|
	  @@config.debug = d
	end
	opts.on("-f","Emulate firewall") do |f|
	  @@config.firewall = f
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
@@log.level=@@config.debug_level=Logger::INFO
@@log.datetime_format=""


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
        #raise "This is a test"
        outstr=@server.generate_html_stats
      rescue Exception=>e
        outstr="Exception: #{e}\n#{e.backtrace.join("\n")}"
      end
      out.write(outstr)
    end    
  end
end
mongrel_server=Mongrel::HttpServer.new("0.0.0.0",@@config.port+1)
@@log.info("Mongrel server listening on port: #{@@config.port+1}")
mongrel_server.register("/",MongrelServerHandler.new(server))
mongrel_server.run
                        

#set root directory
server.file_service.root=@@config.file_root
server.file_service.default_chunk_size = @@config.chunk_size
EventMachine::run {
	host,port=@@config.host, @@config.port
  EventMachine::start_server host,port,PDTPProtocol
  @@log.info("accepting connections with ev=#{EventMachine::VERSION}")
  @@log.info("host=#{host}  port=#{port}")
}

