require File.dirname(__FILE__)+'/client_file_service'
require "thread"
require "net/http"

class HTTPException < Exception
  attr_accessor :code
  def initialize(code,message)
    super(message)
    @code=code
  end
end
    

class ClientTransferBase
  attr_reader :peer, :url, :chunkid, :transfer_direction, :finished
  attr_reader :connection_direction
  attr :range, :local_range
  attr_reader :thread

  attr :server_connection, :file_service

  def parse_http_range(string)
    begin
      arr=string.split("-")
      raise if arr.size!=2
      return arr[0].to_i..arr[1].to_i
    rescue
      raise HTTPException.new(400,"Range string: #{string.inspect} unparseable")
    end
  end

end

#This class implements the listening end of a peer to peer http connection
class ClientTransferListener < ClientTransferBase
  attr :request,:response
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
    
    method=@request.params["REQUEST_METHOD"]
    if method=="GET" then
      @transfer_direction=:out
    elsif method=="PUT" then
      @transfer_direction=:in
    else
      raise HTTPException.new(400,"Invalid method: #{method}")
    end

    #Mongrel doesn't seem to give us the remote port, but it isnt used anyway so just set to 0
    @peer= [ @request.params["REMOTE_ADDR"] , 0 ]
    path=@request.params["REQUEST_PATH"]
    
		#FIXME get these values in some real way
		vserver="bla.com"
    @url="pdtp://"+vserver+path
    
    info=@file_service.get_info(@url)
    raise HTTPException.new(404,"File #{@url} not found") if (info.nil? and transfer_direction == :out)
    
    @range=parse_http_range(request.params["HTTP_RANGE"])
    @connection_direction=:in

    #Takes a range of bytes in a file and converts to the correct chunk and range local to that chunk
    @chunkid,@local_range=info.internal_range(@range)
  
    @@log.debug("Got request, chunkid=#{@chunkid} range=#{@range}")        
  end

  def run
    @thread=Thread.current
    
		ask_verify={
			"type"=>"ask_verify",
			"peer"=>@peer,
			"url"=>@url,
			"chunk_id"=>@chunkid
		}
		@@log.debug("Sending ask_verify")
		@server_connection.send_message(ask_verify)
		
		#Execution of this thread must be stopped until the server has verified this transfer.
		#Once the server has done so by sending a tell_verify message, the thread will be restarted
		@@log.debug("Stopping thread execution: thread=#{@thread.inspect}")
		Thread.stop

	  info = @file_service.get_info(@url)
		
		if @transfer_direction == :in then
		  #Request was a PUT, so now we just have to read the body of the request
			@@log.debug("BODY DOWNLOADED: #{@request.body.read}")
			info.set_chunk_data(@chunkid, @request.body.read)
			@response.start(200) do |head,out| 
			end
		else 
		  #Request was GET, so now we need to send the data
			@response.start(200) do |head,out|
      	head['Content-Type'] = 'application/octet-stream'

      	data=info.chunk_data(@chunkid,@local_range)
      	out.write(data)
    	end
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
    @peer=message["peer"]
    @transfer_direction = message["transfer_direction"].to_sym
    raise if transfer_direction != :out and transfer_direction != :in
    @chunkid=message["chunk_id"]
    @url=message["url"]
    
  end
    
  def run
    begin
    @@log.debug("RUNNING - transfer_direction: #{@transfer_direction}")
    @thread=Thread.current
    uri=URI.parse(@url)
    info=@file_service.get_info(@url)
		range=info.chunk_range(@chunkid)
    
		if @transfer_direction == :in then
		  req = Net::HTTP::Get.new(uri.path)
			body = nil
		else 
		  req = Net::HTTP::Put.new(uri.path)
			#Assumes the entre chunk
			body = info.chunk_data(@chunkid)
		end
    
    req.add_field("Range", "#{range.begin}-#{range.end}")
		res = Net::HTTP.start(peer[0], peer[1]) {|http| http.request(req,body) }
    
    if res.code=='200' and @transfer_direction == :in then
      @@log.debug("BODY DOWNLOADED: #{res.body}")
      info.set_chunk_data(@chunkid,res.body) # assumes we requested entire chunk
      msg={
        "type"=>"completed",
        "url"=>@url,
        "chunk_id"=>@chunkid
      }
      @server_connection.send_message(msg)
    end  

    rescue Exception=>e
      puts "Exception: #{e.to_s} line=#{e.backtrace[0]}"
    end
  end
end
