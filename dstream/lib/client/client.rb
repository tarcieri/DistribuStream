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
		@mutex = Mutex.new
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
  

  #Returns a transfer object if the given connection is a peer associated with 
	#that transfer. Otherwise returns nil
  def get_transfer(connection)
	  @transfers.each do |t|
		  return t if t.peer == connection
		end
		return nil
	end


  #handler for Mongrel (called in a separate thread, one for each client)
  def process(request,response)
		begin
      transfer=ClientTransferListener.new(request,response,@server_connection,@file_service,self)
      @@log.debug "Created TransferListener peer=#{transfer.peer}"  
     
		  #Needs to be locked because multiple threads could attempt to append a transfer at once
			@mutex.synchronize do
				@transfers << transfer
			end

			transfer.run
     
    rescue HTTPException=>e
      response.start(e.code) do |head,out|
        out.write(e.to_s + "\n\n" + e.backtrace.join("\n"))
      end
    rescue Exception=>e 
      response.start(500) do |head,out|
        out.write("Server error, unknown exception\n"+e.to_s+"\n\n"+e.backtrace.join("\n"))
      end
    end    

  end


	def transfer_matches?(transfer, message)
		return( transfer.peer[0] == message["peer"][0] and 
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

			if !@@config.provide then
			  request={
					"type"=>"request",
					"chunk_range"=> 0..2,
					"url"=> message["url"]
				}
				connection.send_message(request)
			end


		when "transfer"
      transfer=ClientTransferConnector.new(message,@server_connection,@file_service)

      @@log.debug("TRANSFER STARTING")
      Thread.new(transfer) do |t|
        t.run
      end
     
    when "tell_verify"
			@transfers.each do |t|
        if transfer_matches?(t, message) then
          # if the server does not authorize the transfer, kill it and the associated connection
          if !message["is_authorized"] then
            @transfers.delete(t)
            t.peer.close_connection
          else
						@@log.debug("Restarting thread execution: thread=#{t.thread.inspect}")
						t.thread.run
          end
				  break
        end
      end
		else
      raise "from server: unknown message type: #{message['type']} "
    end
  end

  #Prints the number of transfers associated with this client
  def print_stats
    @@log.debug "client:  num_transfers=#{@transfers.size}"
  end

	#Provides a threadsafe mechanism for transfers to report themselves finished
	def finished(transfer)
		@mutex.synchronize do
			@transfers.delete(transfer)
		end
	end
	
	#This function is provided so that messages can be identified by unique id's
	#It is not currently implemented on the client, but may be in the future
	def get_id(connection)
	  return nil
	end

end
