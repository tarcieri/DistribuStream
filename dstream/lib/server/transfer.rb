require File.dirname(__FILE__)+'/server_config'

class Transfer
  @@unique_id=0
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

    #compute transfer id
    @transfer_id=@@unique_id.to_s
    @@unique_id+=1
  end

  def to_s
		return "taker=#{@taker}, giver=#{@giver}, connector=#{@connector}, acceptor=#{@acceptor}, url=#{@url}, chunk_id=#{@chunkid}"
	end

end
