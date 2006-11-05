require File.dirname(__FILE__) + '/message'

# handles ResponsePackets, produces RequestPackets
# the addresses used in the network simulator are simply references to the 
# MessageManagers of the nodes on the network
class NetworkSimulator < MessageClient

  def dispatch_from(message,from)
    return false if message.class != ResponsePacket
    message.dest.post(RequestPacket.new(from,message.data) )
  end  
end
