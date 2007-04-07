require 'rubygems'
require 'eventmachine'
require 'optparse'
require 'mongrel'
require File.dirname(__FILE__)+'/client'
require File.dirname(__FILE__)+'/client_file_service'
require File.dirname(__FILE__)+'/../server/server_file_service'
require File.dirname(__FILE__)+'/../common/common_init'

common_init("dstream_client")

def find_files(base_path)
  require 'find'

  found=[]
  excludes=[ ".svn", "CVS" ]
  base_full=File.expand_path(base_path)

  Find.find(base_full) do |path|
    if FileTest.directory?(path)
      if excludes.include?(File.basename(path)) then
        Find.prune
      else
        next
      end
    else
      filename=path[base_full.size+1 .. 10000] #the entire file path after the base_path
      found << filename
    end
  end

  return found
end

class FileServiceProtocol < PDTPProtocol
  
  def initialize *args
    super
  end

  def connection_completed

    begin
    listen_port=@@config[:listen_port]

    #create the client
    client=Client.new
    PDTPProtocol::listener=client
    client.server_connection=self
    client.my_id=Client::generate_client_id(listen_port)


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
      "type"=>"client_info",
      "listen_port"=>listen_port,
      "client_id"=>client.my_id
    }
    send_message(request)

    @@log.info("This client is providing")
    sfs=ServerFileService.new
    sfs.root=@@config[:file_root]
    client.file_service=sfs #give this client access to all data

    hostname="bla.com"

    #provide all the files in the root directory
    files=find_files(@@config[:file_root] )
    files.each do |file|
      request={
        "type"=>"provide",
        "url"=>"http://#{hostname}/#{file}"
      }
      send_message(request)    
    end

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

EventMachine::run {
	host,port,listen_port = @@config[:host],@@config[:port],@@config[:listen_port]
  connection=EventMachine::connect host,port,FileServiceProtocol
  @@log.info("connecting with ev=#{EventMachine::VERSION}")
  @@log.info("host= #{host}  port=#{port}")
  
}



