require File.dirname(__FILE__) + '/client_info'
require File.dirname(__FILE__) +'/transfer'

class Server
  attr_reader :connections
  attr_accessor :file_service
  def initialize()
    @connections = Array.new
    @transfers = Array.new
  end

  def connection_created(connection)
    @connections << connection
  end  

  def connection_destroyed(connection)
    @connections.delete(connection)
  end

  def print_stats
    puts "num_connections=#{@connections.size} num_transfers=#{@transfers.size}"
  end
  
  # returns the ClientInfo object associated with this connection
  def client_info(connection)
    return connection.user_data||=ClientInfo.new
  end

  # runs through the list of requested chunks for each client and creates as many
  # new transfers as it can
  def spawn_transfers
    while spawn_single_transfer_slow==true 
    end
  end

  def begin_transfer(taker,giver,url,chunkid)
    puts "transfer starting: taker=#{taker} giver=#{giver} "
    puts "  url=#{url}  chunkid=#{chunkid}"
    client_info(taker).chunk_info.transfer(url,chunkid..chunkid)
   
    @transfers << Transfer.new(taker,giver,url,chunkid,file_service) 
  end

  # performs a brute force search to pair clients together, 
  # creates a transfer if possible.
  # returns true if a connection was created
  def spawn_single_transfer_slow
    connections.each do |c|
      client=client_info(c)
      client.chunk_info.each_chunk_of_type(:requested) do |url,chunkid|
        #puts "#{a} : #{b}"
        #look for another client that has this chunk
        connections.each do |c2|
          next if c2==c
          if client_info(c2).chunk_info.provided?(url,chunkid) then
            begin_transfer(c,c2,url,chunkid)
            return true
          end
        end
      end
    end  
    return false
  end

  #returns true if the specified transfer exists
  def transfer_authorized?(peer,url,chunkid)
    #since the ask_verify message comes from the listener,
    #we must make sure that the peer is equal to the connector in an authorized
    #transfer
    
    @transfers.each do |t|
			#TODO	
      #server has no idea which port the peers are communicating on, so only check the address
      #this isn't a great way to do this, come up with better ideas
			if t.connector.get_peer_info[0]==peer[0] and t.url==url and t.chunkid==chunkid then
        # do we need to check transfer state here??
        return true
      end
    end
    return false
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
      spawn_transfers #this should also be called periodically, but it is called here to improve latency
    when "provide"
      client_info(connection).chunk_info.provide(message["url"],message["chunk_range"])
      spawn_transfers
    when "unrequest"
      client_info(connection).chunk_info.unrequest(message["url"],message["chunk_range"])
    when "unprovide"
      client_info(connection).chunk_info.unrpovide(message["url"],message["chunk_range"])
    when "ask_verify"
      ok=transfer_authorized?(message["peer"],message["url"],message["chunk_id"])
      response={
        "type"=>"tell_verify",
        "peer"=>message["peer"],
        "url"=>message["url"],
        "chunk_id"=>message["chunk_id"],
        "is_authorized"=>ok
      }
      connection.send_message(response)
    when "change_port"
      puts "client changed port to #{message["port"].to_i}"
      client_info(connection).listen_port=message["port"].to_i
		when "completed"
		  transfer = nil
			@transfers.each do |t|
				if t.taker == connection and t.url == message['url'] and t.chunkid == message['chunk_id'] then
				 	transfer = t
					break
			  end
		  end

      #the client now has the chunk
      client_info(transfer.taker).chunk_info.provide(message["url"],message["chunk_id"]..message["chunk_id"])
			puts "transfer completed: #{transfer}"
			@transfers.delete(transfer)
				
    else
      raise "Unknown message type: #{message['type']}"
    end

  end

end
    
