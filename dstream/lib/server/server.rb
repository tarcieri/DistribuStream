require File.dirname(__FILE__) + '/transfer_manager'
require File.dirname(__FILE__) + '/../common/message'

class ChunkTransferHandler
  def initialize(address, server)
    @address = address
  end
  
  def connect()
  end
  
  def transfer()
  end
  
  def map()
  end
end

class Server
  attr_reader :connections
  def initialize()
    @connections = Array.new
  end
  
  def add_connection(address)
    handler = ChunkTransferHandler.new(address, self)
	fsm = ChunkTransferHandler_sm.new(handler)
    @connections << { :address => address, :handler => handler, :fsm => fsm } 
  end
  
  def connection(address)
    return_connection = @connections.find { |connection| address = connection[:address] }
	raise "No connection with that address" if return_connection.nil?
    return return_connection	
  end
  
  def Transfer(address)
  end

  def Failed(address)
  end
  
  def Connected(address)
  end

  def TransferSuccess(address)
  end  
  
  def TransferFailure(address)
  end

  def Finished(address)
  end
end
    
