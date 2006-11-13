require File.dirname(__FILE__)+ '/../common/message'
#require File.dirname(__FILE__)+ '/filemanager'

#A server's internal representation of the client
class ClientData
  # Creates the client object with a given address object
  def initialize(address)
    @trusts={}
    @address=address
    #@chunks_provided=ChunksProvided.new
  end

  attr_accessor :rank #global peer rank of this client
  attr_accessor :trusts #list of trust relationships between other clients
  attr_accessor :chunks_provided
  attr_accessor :address
end


# The server object manages network state
class TransferManager < MessageClient
  attr_accessor :file_manager

  def initialize  
    @clients={}
  end

  #sends out a transfer packet to the connector
  # *connector: address of client that connects
  # *listener: address of listener (may be client or server)
  # *mode: either :give or :take.  determines the direction of transfer (relative to the connector)
  # *path: location of file to transfer
  # *chunkid: integer number of the chunk to transfer
  def start_transfer(connector,listener,mode,path,chunkid)
    data={
      :type=>:transfer,
      :listener=>listener,
      :mode=>mode,
      :path=>path,
      :chunkid=>chunkid
    }
    post( ResponsePacket.new(connector,data) )
  end

  def dispatch(message)


    handlers={
      RequestPacket=> :dispatch_packet
    }

    handler=handlers[ message.class ]
    return false if handler.nil?

    method(handler).call(message)
    return true
  end

  def dispatch_packet(packet)
    #add a client if they just connected
    client=@clients[packet.source]||=ClientData.new(packet.source)

    handlers={
      :ask_info=> :dispatch_askinfo
    }

    handler=handlers[ packet.data[:type] ]
    method(handler).call(client,packet.data)

  end


  def dispatch_askinfo(client,data)
    ret= {
      :type => :tell_info,
      :path => data[:path]
    }
    post(ResponsePacket.new(client.address,ret))
  end

=begin
   ret= {
      :type => :tellinfo,
      :filename => packet[:filename]
   }
   info=file_manager.get_info( packet[:filename])
   if info==nil
      ret[:status]=:notfound
   else
      ret[:size]=info.size
      ret[:status]=:normal
   end
=end
end
