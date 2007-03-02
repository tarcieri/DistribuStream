require File.dirname(__FILE__)+'/client_file_service'
require "thread"
require "net/http"
require "uri"


class HTTPException < Exception
  attr_accessor :code
  def initialize(code,message)
    super(message)
    @code=code
  end
end
    

class ClientTransferBase
  attr :peer, :port
  attr_reader :url, :byte_range

  attr_reader  :finished
 
  attr_reader :thread

  attr :server_connection, :file_service

  def parse_http_range(string)
    begin
      arr=string.split("-")
      raise if arr.size!=2
      return arr[0].to_i..arr[1].to_i
    rescue
      return nil
    end
  end

end

#This class implements the listening end of a peer to peer http connection
class ClientTransferListener < ClientTransferBase
  attr :request,:response
  attr_accessor :authorized
  #called with the request and response parameters given by Mongrel
  def initialize(request,response,server_connection,file_service,client)
    #FIXME I included a reference to the client because it seems necessary to inform the
		#client of a finished transfer so that it can remove that transfer from the list of
		#transfers. This came up when requesting the same file twice from the same host with 
		#the same peer. Basically there were two identical entries in the list, but the thread
		#reference in one of them was invalid because it had already been killed
		@client = client
		@request,@response=request,response
    @server_connection,@file_service=server_connection,file_service
    @authorized=false  

    puts "params=#{@request.params.inspect}"    
    @method=@request.params["REQUEST_METHOD"].downcase   

    #Mongrel doesn't seem to give us the remote port, but it isnt used anyway so just set to 0
    @peer=@request.params["REMOTE_ADDR"]

    #here we construct the GUID for this file
    #note that Galen and James are both unhappy about different respects of this operation
    #this is very hackish and evil and we will all go to hell because of it
    path=@request.params["REQUEST_PATH"]
		vhost=@request.params["HTTP_HOST"]
    @url="pdtp://"+vhost+path
    
    @byte_range=parse_http_range(request.params["HTTP_RANGE"])
  
    @@log.debug("Got request,  range=#{@byte_range.inspect}")        
  end

  def run
    @thread=Thread.current
    
		ask_verify={
			"type"=>"ask_verify",
			"peer"=>@peer,
			"url"=>@url,
			"range"=>@byte_range
		}
		@@log.debug("Sending ask_verify")
		@server_connection.send_message(ask_verify)
		
		#Execution of this thread must be stopped until the server has verified this transfer.
		#Once the server has done so by sending a tell_verify message, the thread will be restarted
		@@log.debug("Stopping thread execution: thread=#{@thread.inspect}")
		Thread.stop

    #check if the server authorized us
    if @authorized==false then
      raise HTTPException.new(403,"Forbidden: the server did not authorize this transfer")  
    end

	  info = @file_service.get_info(@url)
    if @method == "put" then
		  #Request was a PUT, so now we just have to read the body of the request
			#@@log.debug("BODY DOWNLOADED: #{@request.body.read}")
      @@log.debug("Body Downloaded: url=#{@url} range=#{@byte_range} peer=#{@peer}")      

      @file_service.set_info(FileInfo.new) if info.nil? #we don't know that info exists before the transfer begins
			info.write(@byte_range.first, @request.body.read)
			@response.start(200) do |head,out| 
			end
		elsif @method=="get" then
      raise HTTPException.new(404,"File not found: #{@url}") if info.nil?
      data=info.read(@byte_range)
      raise HTTPException.new(416,"Invalid range: #{@byte_range.inspect}") if data.nil?		


		  #Request was GET, so now we need to send the data
			@response.start(206) do |head,out|
      	head['Content-Type'] = 'application/octet-stream'
        head['Content-Range'] = "#{@byte_range.first}-#{@byte_range.last}"
        #FIXME must include a DATE header according to http

      	out.write(data)
    	end
		else
      raise HTTPException.new(405,"Invalid method: #{@method}")
    end

    #Make sure this transfer is considered completed from our standpoint
		@@log.debug("Removing from list of transfers")
		@client.finished(self)
  end

end

#This class represents the http transfer between two peers from the connector's perspective
class ClientTransferConnector < ClientTransferBase
  def initialize(message,server_connection,file_service)
    @server_connection,@file_service=server_connection,file_service
    @peer,@port=message["host"],message["port"]
    @method = message["method"]
    @url=message["url"]
    @byte_range=message["range"]
    
  end
    
  def run
    begin
    @@log.debug("RUNNING - method: #{@method}")
    @thread=Thread.current
    
    info=@file_service.get_info(@url)
    
    #compute the vhost and path
    #FIXME work with ports
    uri=URI.split(@url)
    path=uri[5]
    vhost=uri[2]   
 
		if @method == "get" then
		  req = Net::HTTP::Get.new(path)
			body = nil
		elsif @method == "put" then 
		  req = Net::HTTP::Put.new(path)
			body = info.read(@byte_range)
		else
      raise HTTPException.new(405,"Invalid method: #{@method}")
    end
    
    req.add_field("Range", "#{@byte_range.begin}-#{@byte_range.end}")
    req.add_field("Host",vhost)
		res = Net::HTTP.start(@peer,@port) {|http| http.request(req,body) }
    
    if res.code=='206' and @method=="get" then
      #@@log.debug("BODY DOWNLOADED: #{res.body.inspect}")
      @@log.debug("Body Downloaded: url=#{@url} range=#{@byte_range} peer=#{@peer}:#{@port}")
      info.write(@byte_range.first,res.body)
      msg={
        "type"=>"completed",
        "url"=>@url,
        "range"=>@byte_range
      }
      @server_connection.send_message(msg)
    else
      puts "HTTP RESPONSE: code=#{res.code} body=#{res.body}"
    end  

    rescue Exception=>e
      puts "Exception: #{e.to_s} trace=\n#{e.backtrace.join("\n")}"
    end
  end
end
