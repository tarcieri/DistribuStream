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

class ClientTransferListener < ClientTransferBase
  attr :request,:response
  #called with the request and response parameters given by Mongrel
  def initialize(request,response,server_connection,file_service)
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
    vserver="bla.com"
    @url="pdtp://"+vserver+path
    
    info=@file_service.get_info(@url)
    raise HTTPException.new(404,"File #{@url} not found") if info.nil?
    
    @range=parse_http_range(request.params["HTTP_RANGE"])
    @connection_direction=:in

    @chunkid,@local_range=info.internal_range(@range)
  
    @@log.debug("Got request, chunkid=#{@chunkid} range=#{@range}")        
  end

  def run
    @thread=Thread.current
    #FIXME need to ask_auth
    @response.start(200) do |head,out|
      head['Content-Type'] = 'application/octet-stream'

      info=@file_service.get_info(@url)
      
      data=info.chunk_data(@chunkid,@local_range)
      out.write(data)
    end
  end

end

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
    @@log.debug("RUNNING")
    @thread=Thread.current
    uri=URI.parse(@url)
    req = Net::HTTP::Get.new(uri.path)
    
    info=@file_service.get_info(@url)
    range=info.chunk_range(chunkid)
    @@log.debug("chunkid=#{chunkid} range=#{range}")
   
    req.add_field("Range", "#{range.begin}-#{range.end}")
    res = Net::HTTP.start(peer[0], peer[1]) {|http| http.request(req) }
    
    if res.code=='200' then
      info.set_chunk_data(@chunkid,res.body) # assumes we requested entire chunk
      msg={
        "type"=>"completed",
        "url"=>@url,
        "chunk_id"=>@chunkid
      }
      @server_connection.send_message(msg)
    end  

    @@log.debug("BODY DOWNLOADED: #{res.body}")
    rescue Exception=>e
      puts "Exception: #{e.to_s} line=#{e.backtrace[0]}"
    end
  end
end
