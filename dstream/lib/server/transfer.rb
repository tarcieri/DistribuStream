#$: << File.dirname(__FILE__) + '/../common'
#require 'server_chunk_transfer_sm'

class Transfer
  attr_reader :taker, :giver, :url, :chunkid
  attr_reader :connector, :acceptor
  
  def initialize(taker,giver,url,chunkid)
    @taker,@giver,@url,@chunkid=taker,giver,url,chunkid
    
    #if FIREWALL global is set, assume taker is behind firewall
		if OPTIONS[:firewall] then
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
    request={
      "type"=>"transfer",
      "peer"=>[addr,@acceptor.user_data.listen_port], # is there a better way to access this?
      "transfer_direction"=> @connector==@taker ? "in" : "out",
      "url"=>@url,
      "chunk_id"=>@chunkid
    } 

    @connector.send_message(request)
    @state=:start 
  end

	def to_s
		return "taker=#{@taker}, giver=#{@giver}, connector=#{@connector}, acceptor=#{@acceptor}, url=#{@url}, chunk_id=#{@chunkid}"
	end

end
