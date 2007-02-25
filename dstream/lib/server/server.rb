require File.dirname(__FILE__) + '/client_info'
require File.dirname(__FILE__) +'/transfer'

class Server
  attr_reader :connections
  attr_accessor :file_service
  def initialize()
    @connections = Array.new
    @transfers = Array.new
  	@ids = Hash.new
		@id = 0
	end

  def connection_created(connection)
    @@log.info("#{@id} Client connected: #{connection.get_peer_info.inspect}")
    @connections << connection
		@ids[connection] = @id
		@id += 1
  end  

  def connection_destroyed(connection)
    @@log.info("#{@ids[connection]} Client connection closed")
    @connections.delete(connection)
  end

  def get_id(connection)
	  return @ids[connection]
	end

  def print_stats
    puts "num_connections=#{@connections.size} num_transfers=#{@transfers.size}"
  end
  
  # returns the ClientInfo object associated with this connection
  def client_info(connection)
    return connection.user_data ||= ClientInfo.new
  end

  # runs through the list of requested chunks for each client and creates as many
  # new transfers as it can
  def spawn_transfers
    while spawn_single_transfer_slow==true 
    end
  end

  # called when a transfer either finishes, successfully or not
  def transfer_completed(transfer)
      
      #FIXME assumes success right now
      #the client now has the chunk
      client_info(transfer.taker).chunk_info.provide(transfer.url,transfer.chunkid..transfer.chunkid)

      @@log.debug("#{@ids[transfer.giver]}->#{@ids[transfer.taker]} transfer completed: #{transfer}")
    
      c1=client_info(transfer.taker)
      c2=client_info(transfer.giver)
 
      #puts "taker trusts giver with: #{c1.trust.weight(c2.trust)}"
      #puts "giver trusts taker with: #{c2.trust.weight(c1.trust)}"
 
      #update trust
      c1.trust.success(c2.trust)
      
      @@log.debug("#{@ids[transfer.taker]}->#{@ids[transfer.giver]} taker trusts giver with: #{c1.trust.weight(c2.trust)}")
      @@log.debug("#{@ids[transfer.giver]}->#{@ids[transfer.taker]} giver trusts taker with: #{c2.trust.weight(c1.trust)}")
 			@transfers.delete(transfer)

  end

  def begin_transfer(taker,giver,url,chunkid)
    @@log.debug("#{@ids[giver]}->#{@ids[taker]} transfer starting: taker=#{taker} giver=#{giver} url=#{url}  chunkid=#{chunkid}")
    client_info(taker).chunk_info.transfer(url,chunkid..chunkid)
   
    @transfers << Transfer.new(taker,giver,url,chunkid,file_service) 
  end

  # performs a brute force search to pair clients together, 
  # creates a transfer if possible.
  # returns true if a connection was created
  def spawn_single_transfer_slow
    feasible_peers=[]
    connections.each do |c|
      client=client_info(c)
      client.chunk_info.each_chunk_of_type(:requested) do |url,chunkid|
        #puts "#{a} : #{b}"
        #look for another client that has this chunk
        connections.each do |c2|
          next if c2==c
          if client_info(c2).chunk_info.provided?(url,chunkid) then
            feasible_peers << c2 
          end
        end

        # we now have a list of clients that have the requested chunk.
        # pick one and start the transfer
        if feasible_peers.size>0 then
          giver=feasible_peers[rand(feasible_peers.size)]
          begin_transfer(c,giver,url,chunkid)
          return true
        end

      end #requested chunks
    end #clients

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
        response["size"]=info.file_size
        response["chunk_size"]=info.base_chunk_size
        response["streaming"]=info.streaming
      end
      connection.send_message(response)

    when "request"
      chunk_range=@file_service.get_info(message["url"]).chunk_range_from_byte_range(message["range"],false)
      client_info(connection).chunk_info.request(message["url"],chunk_range)
      spawn_transfers #this should also be called periodically, but it is called here to improve latency
    when "provide"
      #puts message.inspect
      chunk_range=@file_service.get_info(message["url"]).chunk_range_from_byte_range(message["range"],true)  
      client_info(connection).chunk_info.provide(message["url"],chunk_range)
      spawn_transfers
    when "unrequest"
      chunk_range=@file_service.get_info(message["url"]).chunk_range_from_byte_range(message["range"],false)
      client_info(connection).chunk_info.unrequest(message["url"],chunk_range)
    when "unprovide"
      chunk_range=@file_service.get_info(message["url"]).chunk_range_from_byte_range(message["range"],false)
      client_info(connection).chunk_info.unprovide(message["url"],chunk_range)
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
      client_info(connection).listen_port=message["port"].to_i
		when "completed"
		  transfer = nil
			@transfers.each do |t|
				if t.taker == connection and t.url == message['url'] and t.chunkid == message['chunk_id'] then
				 	transfer = t
					break
			  end
		  end

      transfer_completed(transfer)
				
    else
      raise "Unknown message type: #{message['type']}"
    end

  end

end
    
