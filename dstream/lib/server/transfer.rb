require File.dirname(__FILE__)+'/server_config'

class Transfer
  attr_reader :taker, :giver, :url, :chunkid
  attr_reader :connector, :acceptor, :byte_range
  attr_accessor :transfer_id
 
	@@config = ServerConfig.instance

  def initialize(taker,giver,url,chunkid,byte_range)
    @taker,@giver,@url,@chunkid,@byte_range=taker,giver,url,chunkid,byte_range
    
    #if FIREWALL global is set, assume taker is behind firewall
		if @@config.firewall then
    	@connector=@giver
			@acceptor=@taker
		else
			@connector=@taker
    	@acceptor=@giver
		end
    
    recompute_transfer_id
  end

  def recompute_transfer_id
    id1=connector.user_data.client_id
    id2=acceptor.user_data.client_id
    @transfer_id=Transfer::gen_transfer_id(id1,id2,@url,@byte_range)
  end
  
  def Transfer::gen_transfer_id(id1,id2,url,byte_range)
    a = id1<id2 ? id1 : id2
    b = id1<id2 ? id2 : id1
    return "#{a}$#{b}$#{url}$#{byte_range}"
  end

  def to_s
		return "taker=#{@taker}, giver=#{@giver}, connector=#{@connector}, acceptor=#{@acceptor}, url=#{@url}, chunk_id=#{@chunkid} range=#{@byte_range}"
	end

  def debug_str
    str=""
    str=str+"to_s=#{to_s}"
    str=str+"   taker_id=#{@taker.user_data.client_id} giver_id=#{@giver.user_data.client_id}" 
    return str
  end

end
