require File.dirname(__FILE__) + '/client_info'
require File.dirname(__FILE__) +'/transfer'
require "thread"

class Server
  attr_reader :connections
  attr_accessor :file_service
  def initialize()
    @connections = Array.new
    #@transfers = Hash.new #keyed on Transfer::hash
  	@ids = Hash.new
		@id = 0
    @stats_mutex=Mutex.new
	end

  def connection_created(connection)
    @stats_mutex.synchronize do
      @@log.info("#{@id} Client connected: #{connection.get_peer_info.inspect}")
      @connections << connection
		  @ids[connection] = @id
		  @id += 1
    end
  end  

  def connection_destroyed(connection)
    @stats_mutex.synchronize do
      @@log.info("#{@ids[connection]} Client connection closed")
      @connections.delete(connection)
    end
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
  def transfer_completed(transfer,chunk_hash)      

      # did the transfer complete successfully?
      local_hash=@file_service.get_chunk_hash(transfer.url,transfer.chunkid)

      if chunk_hash==nil then
        success=true
        send_response=false
      else
        success= local_hash==chunk_hash 
        send_response=true
      end
      
      c1=client_info(transfer.taker)
      c2=client_info(transfer.giver)

      if success then
        #the taker now has the file, so he can provide it
        client_info(transfer.taker).chunk_info.provide(transfer.url,transfer.chunkid..transfer.chunkid)
        c1.trust.success(c2.trust)
      else
        #transfer failed, the client still wants the chunk
        client_info(transfer.taker).chunk_info.request(transfer.url,transfer.chunkid..transfer.chunkid)
        c1.trust.failure(c2.trust)
      end  

      outstr="#{@ids[transfer.giver]}->#{@ids[transfer.taker]} transfer completed: #{transfer}"
      outstr=outstr+" t->g=#{c1.trust.weight(c2.trust)} g->t=#{c2.trust.weight(c1.trust)}" 
      @@log.debug(outstr)
    
      if send_response then
        msg={
          "type"=>"hash_verify",
          "url"=>transfer.url,
          "range"=>transfer.byte_range,
          "hash_ok"=>success
        }
        transfer.taker.send_message(msg)
      end

 			client_info(transfer.taker).transfers.delete(transfer.transfer_hash)
      client_info(transfer.giver).transfers.delete(transfer.transfer_hash)

      spawn_transfers_for_client(transfer.taker)
      spawn_transfers_for_client(transfer.giver)

  end

  def begin_transfer(taker,giver,url,chunkid)
    @@log.debug("#{@ids[giver]}->#{@ids[taker]} transfer starting: taker=#{taker} giver=#{giver} url=#{url}  chunkid=#{chunkid}")
    client_info(taker).chunk_info.transfer(url,chunkid..chunkid)
   
    t=Transfer.new(taker,giver,url,chunkid,file_service)
    #@transfers[t.hash] = t
    client_info(taker).transfers[t.transfer_hash]=t
    client_info(giver).transfers[t.transfer_hash]=t
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

  #spawns uploads and downloads for this client.
  #should be called every time there is a change that would affect 
  #what this client has or wants
  def spawn_transfers_for_client(client_connection)
    info=client_info(client_connection)

    while info.wants_download? do
      break if spawn_download_for_client(client_connection) == false
    end

    while info.wants_upload? do
      break if spawn_upload_for_client(client_connection) == false
    end
  end

  def spawn_download_for_client(client_connection)
    feasible_peers=[]

    c1info=client_info(client_connection)
    begin
      url,chunkid=c1info.chunk_info.high_priority_chunk
    rescue
      return false
    end

    connections.each do |c2|
      next if client_connection==c2
      if client_info(c2).chunk_info.provided?(url,chunkid) then
        #FIXME check if this client wants to upload
        feasible_peers << c2
      end
    end

    # we now have a list of clients that have the requested chunk.
    # pick one and start the transfer
    if feasible_peers.size>0 then
      #FIXME base this on the trust model
      giver=feasible_peers[rand(feasible_peers.size)]
      begin_transfer(client_connection,giver,url,chunkid)
      return true
    end

    return false
  end

  def spawn_upload_for_client(client_connection)
    c1info=client_info(client_connection)

    connections.each do |c2|
      next if client_connection==c2
    
      begin
        url,chunkid=client_info(c2).chunk_info.high_priority_chunk
      rescue
        return false
      end

      if c1info.chunk_info.provided?(url,chunkid) then
        begin_transfer(c2,client_connection,url,chunkid)
        return true
      end
    end

    return false
  end

  def dispatch_message(message,connection)
    @stats_mutex.synchronize do
      dispatch_message_needslock(message,connection)
    end
  end

  #handles the request, provide, unrequest, unprovide messages
  def handle_requestprovide(connection,message)
    type=message["type"]
    url=message["url"]
    info=@file_service.get_info(url) rescue nil
    raise ProtocolWarn.new("Requested URL: '#{url}' not found") if info.nil?
    
    exclude_partial= (type=="provide") #only exclude partial chunks from provides
    range=info.chunk_range_from_byte_range(message["range"],exclude_partial)

    #call request, provide, unrequest, or unprovide
    client_info(connection).chunk_info.send( type.to_sym, url, range)
    spawn_transfers_for_client(connection)
  end

  def dispatch_message_needslock(message,connection)
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
      handle_requestprovide(connection,message)
    when "provide"
      handle_requestprovide(connection,message)
    when "unrequest"
      handle_requestprovide(connection,message)
    when "unprovide"
      handle_requestprovide(connection,message)
    when "ask_verify"
      hash=Transfer::transfer_hash(message["peer"],connection.get_peer_info[0],message["url"],message["range"])
      ok= client_info(connection).transfers[hash] ? true : false
      response={
        "type"=>"tell_verify",
        "peer"=>message["peer"],
        "url"=>message["url"],
        "range"=>message["range"],
        "is_authorized"=>ok
      }
      connection.send_message(response)
    when "change_port"
      client_info(connection).listen_port=message["port"].to_i
		when "completed"
      transfer_hash=Transfer::transfer_hash(message["peer"],connection.get_peer_info[0],message["url"],message["range"])
		  transfer=client_info(connection).transfers[transfer_hash]
      if transfer and transfer.taker==connection then
        transfer_completed(transfer,message["hash"])
      else
        raise ProtocolWarn.new("You sent me a transfer completed message for unknown transfer: #{transfer_hash}")
      end
		
    when "protocol_error"
      #ignore
    when "protocol_warn"
      #ignore	
    else
      raise "Unhandled message type: #{message['type']}"
    end

  end

  def connection_name(c)
    host,port=c.get_peer_info
    return "#{get_id(c)}: #{host}:#{port}"
  end

  def generate_html_stats
    @stats_mutex.synchronize do
      return generate_html_stats_needslock
    end
  end

  def generate_html_stats_needslock

    s=String.new
    s=s+"<html><head><title>PDTP Statistics</title></head>"
    s=s+"<body>Time=#{Time.new.to_s} "

    s=s+"<center><table border=1>"
    s=s+"<tr><th>Client</th><th>Downloads</th><th>Files</th></tr>"

    @connections.each do |c|
     
      transfers=""
      client_info(c).transfers.each do |key,t|
        if c==t.giver then
          str="UP: "
          peer=t.taker
        else
          str="DOWN: "
          peer=t.giver
        end
          
        
        str=str+"url=#{t.url} peer=#{connection_name(peer)} range=#{t.byte_range}"
        transfers=transfers+str+"<br>"
      end

      files=""
      stats=client_info(c).chunk_info.get_file_stats
      stats.each do |fs|
        
        files=files+"#{fs.url} size=#{fs.file_chunks} req=#{fs.chunks_requested}"
        files=files+" prov=#{fs.chunks_provided} transf=#{fs.chunks_transferring}<br>"    
      end      

      s=s+"<tr><td>#{connection_name(c)}</td><td>#{transfers}</td><td>#{files}</td></tr>"
    end 

    s=s+"</table>"

    s=s+"</body></html>"

    return s
  end

end
    
