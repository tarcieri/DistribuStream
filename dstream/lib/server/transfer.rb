#$: << File.dirname(__FILE__) + '/../common'
#require 'server_chunk_transfer_sm'

class Transfer
  attr_reader :taker, :giver, :url, :chunkid
  attr_reader :connector, :acceptor
  
  def initialize(taker,giver,url,chunkid)
    @taker,@giver,@url,@chunkid=taker,giver,url,chunkid
    
    #assume neither client is behind a firewall at this point
    @connector=@taker
    @acceptor=@giver
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
 
  def connect()
  end

  def transfer()
  end

  def map()
  end

  def execute_transition(message)
    @fsm.method(message).call
  end  
end
