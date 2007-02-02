#require File.dirname(__FILE__) + '/transfer_manager'
require File.dirname(__FILE__) + '/client_info'

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
  attr_accessor :file_service
  def initialize()
    @connections = Array.new
  end

  def connection_created(connection)
    @connections << connection
  end  

  def connection_destroyed(connection)
    @connections.delete(connection)
  end

  def print_stats
    puts "num_connections=#{@connections.size}"
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

  # returns the ClientInfo object associated with this connection
  def client_info(connection)
    return connection.user_data||=ClientInfo.new
  end

  # runs through the list of requested chunks for each client and creates as many
  # new transfers as it can
  def spawn_transfers
    
  end

  def dispatch_message(message,connection)
    case message["type"]
    
    when "ask_info"
      info=file_service.get_info(message["url"])
      response={
        "type"=>"tell_info",
        "url"=>message["url"]
      }
      unless info.nil?
        response["size"]=info.size
        response["chunk_size"]=info.chunk_size
        response["streaming"]=info.streaming
      end
      connection.send_message(response)

    when "request"
      client_info(connection).chunk_info.request(message["url"],message["chunk_range"])
    
    else
      raise "Unknown message type: #{message['type']}"
    end

  end

end
    
