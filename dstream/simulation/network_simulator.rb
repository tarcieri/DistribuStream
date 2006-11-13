require File.dirname(__FILE__) + '/../lib/common/message'

# handles ResponsePackets, produces RequestPackets
# the addresses used in the network simulator are simply references to the
# MessageManagers of the nodes on the network
class NetworkSimulator < MessageClient

  def dispatch_from(message,from)
    return false if message.class != PacketOut
    message.dest.post(PacketIn.new(from,message.data) )
  end
end
