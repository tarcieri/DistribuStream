require File.dirname(__FILE__)+'/client_file_service'
require "thread"
require "net/http"
require "uri"
require "digest/sha2"


class HTTPException < Exception
  attr_accessor :code
  def initialize(code,message)
    super(message)
    @code=code
  end
end
    

class ClientTransferBase
  attr_reader :peer, :peer_id, :url, :byte_range
  attr_reader :server_connection, :file_service
  attr_reader :method, :client,:hash
  
  def matches_message?(message)
    return ( @peer=message["peer"] and
             @url==message["url"] and
             @byte_range==message["range"] and
             @peer_id==message["peer_id"] )
  end

  def parse_http_range(string)
    begin
      raise "Can't parse range string: #{string}" unless string =~ /bytes=([0-9]+)-([0-9]+)/
      #puts "parsed= #{$1}   #{$2}"
      return (($1).to_i)..(($2).to_i)
    rescue
      return nil
    end
  end

  def send_completed_message(hash)
    message={
      "type"=>"completed",
      "url"=>@url,
      "peer"=>@peer,
      "range"=>@byte_range,
      "peer_id"=>@peer_id,
      "hash"=>hash
    }
    @server_connection.send_message(message)
  end

  def send_ask_verify_message
    message={
      "type"=>"ask_verify",
      "url"=>@url,
      "peer"=>@peer,
      "range"=>@byte_range,
      "peer_id"=>@peer_id
    }
    @server_connection.send_message(message)
  end

end

#This class implements the listening end of a peer to peer http connection
class ClientTransferListener < ClientTransferBase
  attr :request,:response
  #called with the request and response parameters given by Mongrel
  def initialize(request,response,server_connection,file_service,client)
		@request,@response=request,response
    @server_connection,@file_service=server_connection,file_service
    @authorized=false
    @client=client
  end

  def write_http_exception(e)
    if e.class==HTTPException then
      @response.start(e.code) do |head,out|
        out.write(e.to_s + "\n\n" + e.backtrace.join("\n") )
      end
    else
      @response.start(500) do |head,out|
        out.write("Server error, unknown exception:"+e.to_s + "\n\n" + e.backtrace.join("\n") )
      end
    end
  end

  def handle_header
    @thread=Thread.current

    @@log.debug "params=#{@request.params.inspect}"    

    @method=@request.params["REQUEST_METHOD"].downcase   
    @peer=@request.params["REMOTE_ADDR"]

    #here we construct the GUID for this file
    path=@request.params["REQUEST_PATH"]
		vhost=@request.params["HTTP_HOST"]
    @url="http://"+vhost+path
    
    @byte_range=parse_http_range(request.params["HTTP_RANGE"])
    @peer_id=@request.params["HTTP_X_PDTP_PEER_ID"]

    #sanity checking
    raise HTTPException.new(400, "Missing X-PDTP-Peer-Id header") if @peer_id.nil?
    raise HTTPException.new(400, "Missing Host header") if vhost.nil?
    raise HTTPException.new(400, "Missing Range header") if @byte_range.nil?
   
    send_ask_verify_message

    #tell_verify(true)
    Thread.stop
    after_verification
  end

  def tell_verify(authorized)
    @authorized=authorized
    @thread.run
  end

  def after_verification
    
    #check if the server authorized us
    if @authorized==false then
      raise HTTPException.new(403,"Forbidden: the server did not authorize this transfer")  
    end

	  info = @file_service.get_info(@url)
    if @method == "put" then
      #we are the taker
      @@log.debug("Body Downloaded: url=#{@url} range=#{@byte_range} peer=#{@peer}")      

      @file_service.set_info(FileInfo.new) if info.nil? #we don't know that info exists before the transfer begins
			info.write(@byte_range.first, @request.body.read)
      @hash=Digest::SHA256.hexdigest(res.body) rescue nil
      

			@response.start(200) do |head,out| 
			end
		elsif @method=="get" then
      #we are the giver
      raise HTTPException.new(404,"File not found: #{@url}") if info.nil?
      data=info.read(@byte_range)
      raise HTTPException.new(416,"Invalid range: #{@byte_range.inspect}") if data.nil?		

		  #Request was GET, so now we need to send the data
			@response.start(206) do |head,out|
      	head['Content-Type'] = 'application/octet-stream'
        head['Content-Range'] = "bytes #{@byte_range.first}-#{@byte_range.last}/*"
        #FIXME must include a DATE header according to http

      	out.write(data)
    	end
		else
      raise HTTPException.new(405,"Invalid method: #{@method}")
    end

  end

end

#This class represents the http transfer between two peers from the connector's perspective
class ClientTransferConnector < ClientTransferBase
  def initialize(message,server_connection,file_service,client)
    @server_connection,@file_service=server_connection,file_service
    @peer,@port=message["host"],message["port"]
    @method = message["method"]
    @url=message["url"]
    @byte_range=message["range"]
    @peer_id=message["peer_id"]
    @client=client
  end
    
  def run
    hash=nil
    
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
    
    req.add_field("Range", "bytes=#{@byte_range.begin}-#{@byte_range.end}")
    req.add_field("Host",vhost)
    req.add_field("X-PDTP-Peer-Id",@client.my_id)
		res = Net::HTTP.start(@peer,@port) {|http| http.request(req,body) }
    
    if res.code=='206' and @method=="get" then
      #we are the taker
      @@log.debug("Body Downloaded: url=#{@url} range=#{@byte_range} peer=#{@peer}:#{@port}")
      info.write(@byte_range.first,res.body)
      @hash=Digest::SHA256.hexdigest(res.body) rescue nil
    else
      raise "HTTP RESPONSE: code=#{res.code} body=#{res.body}"
    end  

  end
end
