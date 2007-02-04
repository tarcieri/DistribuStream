#$: << File.dirname(__FILE__) + '/../common'
#require 'server_chunk_transfer_sm'

class Transfer
  attr_accessor :taker, :giver, :url, :chunkid
  
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
      "peer_addr"=>addr.to_s,
      "peer_port"=>port.to_i,
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
