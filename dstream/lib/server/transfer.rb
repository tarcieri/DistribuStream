require File.dirname(__FILE__)+'/server_config'

class Transfer
  attr_reader :taker, :giver, :url, :chunkid
  attr_reader :connector, :acceptor, :byte_range
 
	@@config = ServerConfig.instance

  def initialize(taker,giver,url,chunkid,file_service)
    @taker,@giver,@url,@chunkid,@file_service=taker,giver,url,chunkid,file_service
    
    #if FIREWALL global is set, assume taker is behind firewall
		if @@config.firewall then
    	@connector=@giver
			@acceptor=@taker
		else
			@connector=@taker
    	@acceptor=@giver
		end
    send_transfer_message  
  end

  def send_transfer_message
    addr,port=@acceptor.get_peer_info

    # We're going to send byte ranges along with chunk ids.
    @byte_range = @file_service.get_info(@url).chunk_range(@chunkid)

    request={
      "type"=>"transfer",
      "host"=>addr,
      "port"=>@acceptor.user_data.listen_port,
      "method"=> @connector == @taker ? "get" : "put",
      "url"=>@url,
      "range"=> @byte_range
    } 

    @connector.send_message(request)
    @state=:start 
  end

	def to_s
		return "taker=#{@taker}, giver=#{@giver}, connector=#{@connector}, acceptor=#{@acceptor}, url=#{@url}, chunk_id=#{@chunkid}"
	end

  def hash
    return Transfer::hash(@taker.get_peer_info[0],@giver.get_peer_info[0],@url,@byte_range)
  end

  def Transfer::hash(ip1,ip2,url,byte_range)
    hash=url+"#"+byte_range.to_s+"#"
    hash=hash+ ( (ip1<ip2) ? (ip1.to_s+"#"+ip2.to_s) : (ip2.to_s+"#"+ip1.to_s) )
    return hash    
  end

end
