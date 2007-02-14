require "rubygems"
require "eventmachine"
require File.dirname(__FILE__) + '/../common/pdtp_protocol'
require File.dirname(__FILE__) + '/client_transfer'
require 'mongrel'
require 'net/http'
require 'thread'

# This is the main driver for the client-side implementation
# of PDTP. It maintains a single connection to a server and 
# all the necessary connections to peers. It is responsible
# for handling all messages corresponding to these connections.
class Client < Mongrel::HttpHandler

  # Accessor for a client file service instance
  attr_accessor :file_service
  attr_accessor :server_connection

  def initialize
    @transfers = Array.new
  end

  def connection_created(connection)
    #For some reason, we can't use this get_peer_info for a remote connection
    # why?
    #@@log.debug("Opened connection: #{connection.get_peer_info.inspect}")
		@@log.debug("Opened connection...");
  end

  def connection_destroyed(connection)
	  @@log.debug("Closed server connection...")
  end
  
  def get_transfer(connection)
	  @transfers.each do |t|
		  return t if t.peer == connection
		end
	end

  def parse_http_range(string)
    arr=string.split("-")
    raise if arr.size!=2
    return arr[0].to_i..arr[1].to_i
  end

  def range_valid?(url,range)
    info=file_service.get_info(url)
    chunk=range.begin/info.chunk_size
    chunk_start=chunk*info.chunk_size
    chunk_end=chunk_start+file_service.get_chunk_size(url,chunk)-1    
    return range.end<=chunk_end
  end

  #handler for Mongrel (called in a separate thread, one for each client)
  def process(request,response)
    begin
      transfer=ClientTransferListener.new(request,response,@server_connection,@file_service)
      @@log.debug "Created TransferListener peer=#{transfer.peer}"  
      transfer.run
     
    rescue Exception=>e
      response.start(416) do |head,out|
        head['Content-Type'] = 'text/plain'
        out.write(e.to_s+"\n"+e.backtrace.join("\n"))
      end
    end    

  end


	def transfer_matches?(transfer, message)
  	return( transfer.peer.get_peer_info == message["peer"] and 
            transfer.url == message["url"] and
            transfer.chunkid == message["chunk_id"] )
	end

  def dispatch_message(message,connection)
    case message["type"]
    when "tell_info"
			info = FileInfo.new
      info.file_size=message["size"]
      info.base_chunk_size=message["chunk_size"]
      info.streaming=message["streaming"]
      @file_service.set_info(message["url"], info)
    
		when "transfer"
      transfer=ClientTransferConnector.new(message,@server_connection,@file_service)

      @@log.debug("TRANSFER STARTING")
      Thread.new(transfer) do |my_transfer|
        my_transfer.run
      end
     
    when "tell_verify"
      @transfers.each do |t|
        if transfer_matches?(t, message) then
          # if the server does not authorize the transfer, kill it and the associated connection
          if !message["is_authorized"] then
            @transfers.delete(t)
            t.peer.close_connection
          else
						t.peer.send_message({"type"=>"go_ahead"}) if t.transfer_direction == :in
            t.go_ahead=true 
            t.update
          end
 
          break
        end

      end
    
		else
      raise "from server: unknown message type: #{message['type']} "
    end
  end

  def dispatch_message_peer(message,connection)
    case message["type"]
    when "give", "take"
      transfer_direction = message["type"] == "give" ? :out : :in
      new_trans=ClientTransfer.new(
																	 connection,
																	 message["url"],
        													 message["chunk_id"],
																	 transfer_direction,
																	 file_service
																	)
      
      @transfers << new_trans      

      askverify = {
        "type" => "ask_verify",
        "peer" => connection.get_peer_info,
        "url" => message["url"],
        "chunk_id" => message["chunk_id"]
      }
      @server_connection.send_message(askverify)
		
		when "data"
			transfer = get_transfer(connection) 

			completed = {
				"type" => "completed",
				"url" => transfer.url,
				"chunk_id" => transfer.chunkid
			}

      #FIXME check data hash here
      file_service.set_chunk_data(transfer.url, transfer.chunkid, message["data"])		
	
			@server_connection.send_message(completed)
			@transfers.delete(transfer)
			connection.close_connection
    
		when "go_ahead"
			transfer = get_transfer(connection)
			transfer.go_ahead = true
			transfer.update

		else
      raise "from peer: unknown message type: #{message['type']} "
    end
  end

  def print_stats
    @@log.debug "client:  num_transfers=#{@transfers.size}"
  end

	def update_finished_transfers
	  @transfers.each do |t|
		  @transfers.delete(t) if t.finished
		end
	end

end
