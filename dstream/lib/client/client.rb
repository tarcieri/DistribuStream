require "rubygems"
require "eventmachine"
require File.dirname(__FILE__) + '/../common/pdtp_protocol'
require File.dirname(__FILE__) + '/client_transfer'
require 'mongrel'
require 'net/http'
require 'thread'
require 'digest/md5'

# This is the main driver for the client-side implementation
# of PDTP. It maintains a single connection to a server and 
# all the necessary connections to peers. It is responsible
# for handling all messages corresponding to these connections.
class Client < Mongrel::HttpHandler

  # Accessor for a client file service instance
  attr_accessor :file_service
  attr_accessor :server_connection
  attr_accessor :my_id

  def initialize
    @transfers = Array.new
		@mutex = Mutex.new
  end

  def connection_created(connection)
    #For some reason, we can't use this get_peer_info for a remote connection
    # why?
    #@@log.debug("Opened connection: #{connection.get_peer_info.inspect}")
		@@log.debug("[mongrel]Opened connection...");
  end

  def connection_destroyed(connection)
	  @@log.debug("[mongrel]Closed connection...")
  end
  

  #Returns a transfer object if the given connection is a peer associated with 
	#that transfer. Otherwise returns nil
  def get_transfer(connection)
	  @transfers.each do |t|
		  return t if t.peer == connection
		end
		return nil
	end

  def request_uri

  end

  #handler for Mongrel (called in a separate thread, one for each client)
  def process(request,response)
		begin
      @@log.debug "Creating TransferListener"
      transfer=ClientTransferListener.new(request,response,@server_connection,@file_service,self)
       
     
		  #Needs to be locked because multiple threads could attempt to append a transfer at once
			@mutex.synchronize do
				@transfers << transfer
			end

			transfer.handle_header
     
    rescue Exception=>e
      transfer.write_http_exception(e)
    end
      transfer.send_completed_message(transfer.hash)   

  end


	def transfer_matches?(transfer, message)
		return( transfer.peer == message["peer"] and 
            transfer.url == message["url"] and
            transfer.byte_range == message["range"] and
            transfer.peer_id == message["peer_id"] )
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
					"url"=> message["url"],
					"range"=> @@config.byte_start..@@config.byte_end
				}
				connection.send_message(request)
			end


		when "transfer"
      transfer=ClientTransferConnector.new(message,@server_connection,@file_service,self)

      @@log.debug("TRANSFER STARTING")
      Thread.new(transfer) do |t|
        begin
          t.run
        rescue Exception=>e
        end
        t.send_completed_message(t.hash)
      end
     
    when "tell_verify"
      found=false
			@transfers.each do |t|
        if transfer_matches?(t, message) then
		
          #don't need this in the list anymore, its thread will handle it
          finished(t)
          t.tell_verify(message["is_authorized"])
          found=true
				  break
        end
      end

      if found==false then
        puts "BUG: Tell verify sent for an unknown transfer"
        exit!
      end
    when "hash_verify"
      @@log.debug("Hash verified for url=#{message["url"]} range=#{message["range"]} hash_ok=#{message["hash_ok"]}")
		when "protocol_error"
      #ignore
    when "protocol_warn"
      #ignore
    else
      raise "Server sent an unknown message type: #{message['type']} "
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

  def Client::generate_client_id(port=0)
    md5 = Digest::MD5::new
    now = Time::now
    md5.update(now.to_s)
    md5.update(String(now.usec))
    md5.update(String(rand(0)))
    md5.update(String($$))
    #return md5.hexdigest+":#{port}" # long id
    return md5.hexdigest[0..5] # short id
  end

end
