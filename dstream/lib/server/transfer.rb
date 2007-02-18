require File.dirname(__FILE__)+'/server_config'

class Transfer
  attr_reader :taker, :giver, :url, :chunkid
  attr_reader :connector, :acceptor
 
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
    finfo = @file_service.get_info(@url)
    min_byte = @chunkid * finfo.base_chunk_size
    max_byte = min_byte + finfo.base_chunk_size

    request={
      "type"=>"transfer",
      "peer"=>[addr,@acceptor.user_data.listen_port],
      #
      # is there a better way to access this?
      # 
      # Yup:

      "transfer_url" => "http://#{addr}:#{@acceptor.user_data.listen_port}/#{@url}",

      # I'm keeping the peer array so as to not break the
      # Ruby client, but I think we should switch to peer_url.
      #
      # On a more picky note, this:

      "transfer_direction"=> @connector==@taker ? "in" : "out",

      # Strained my brain a bit. I'd rather use the HTTP-ish
      # terms:

      "method" => @connector == @taker ? "get" : "post",

      # Again, keeping both for 'backwards' compatibility,
      # but we should stick to one.

      "url"=>@url,
      "chunk_id"=>@chunkid,

      # Finally, the Java client doesn't actually know what
      # a chunk is. This is sensible, in my view, but we can
      # talk about it. For now, the server should send this
      # byte range information.

      "byte_range" => { "min" => min_byte, "max" => max_byte }
    } 

    @connector.send_message(request)
    @state=:start 
  end

	def to_s
		return "taker=#{@taker}, giver=#{@giver}, connector=#{@connector}, acceptor=#{@acceptor}, url=#{@url}, chunk_id=#{@chunkid}"
	end

end
