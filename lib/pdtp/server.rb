#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

require File.dirname(__FILE__) + '/common/protocol'
require File.dirname(__FILE__) + '/common/common_init'
require File.dirname(__FILE__) + '/server/file_service'
require File.dirname(__FILE__) + '/server/client_info'
require File.dirname(__FILE__) + '/server/transfer'

require 'thread'
require 'erb'

module PDTP
  # PDTP server implementation
  class Server
    attr_reader :connections
    attr_accessor :file_service
    def initialize
      @connections = Array.new
      @stats_mutex=Mutex.new
      @used_client_ids=Hash.new #keeps a list of client ids in use, they must be unique
      @updated_clients=Hash.new #a set of clients that have been modified and need transfers spawned
    end

    #called by pdtp_protocol when a connection is created
    def connection_created(connection)
      @stats_mutex.synchronize do
        @@log.info "Client connected: #{connection.get_peer_info.inspect}"
        connection.user_data = ClientInfo.new
        @connections << connection 
      end
    end  

    #called by pdtp_protocol when a connection is destroyed
    def connection_destroyed(connection)
      @stats_mutex.synchronize do
        @@log.info "Client connection closed: #{connection.get_peer_info.inspect}"
        @connections.delete connection
      end
    end

    # returns the ClientInfo object associated with this connection
    def client_info(connection)
      connection.user_data ||= ClientInfo.new
    end

    # called when a transfer either finishes, successfully or not
    def transfer_completed(transfer,connection,chunk_hash,send_response=true)      
      # did the transfer complete successfully?
      local_hash=@file_service.get_chunk_hash(transfer.url,transfer.chunkid)

      c1=client_info(transfer.taker)
      c2=client_info(transfer.giver)

      if connection==transfer.taker
        success= (chunk_hash==local_hash)

        if success
          #the taker now has the file, so he can provide it
          client_info(transfer.taker).chunk_info.provide(transfer.url,transfer.chunkid..transfer.chunkid)
          c1.trust.success(c2.trust)
        else
          #transfer failed, the client still wants the chunk
          client_info(transfer.taker).chunk_info.request(transfer.url,transfer.chunkid..transfer.chunkid)
          c1.trust.failure(c2.trust)
        end 

        transfer.taker.send_message(:hash_verify, 
          :url => transfer.url, 
          :range => transfer.byte_range, 
          :hash_ok => success
        ) if send_response
      end

      #outstr="#{@ids[transfer.giver]}->#{@ids[transfer.taker]} transfer completed: #{transfer}"
      #outstr=outstr+" t->g=#{c1.trust.weight(c2.trust)} g->t=#{c2.trust.weight(c1.trust)}" 
      #outstr=outstr+"sent_by: "+ ( connection==transfer.taker ? "taker" : "giver" )
      #outstr=outstr+" success=#{success} "
      #@@log.debug(outstr)

      #remove this transfer from whoever sent it
      client_info(connection).transfers.delete(transfer.transfer_id)
      @updated_clients[connection]=true #flag this client for transfer creation
    end

    #Creates a new transfer between two peers
    #returns true on success, or false if the specified transfer is already in progress
    def begin_transfer(taker, giver, url, chunkid)
      byte_range = @file_service.get_info(url).chunk_range(chunkid) 
      t = Transfer.new(taker, giver, url, chunkid, byte_range)

      #make sure this transfer doesnt already exist
      t1 = client_info(taker).transfers[t.transfer_id]
      t2 = client_info(giver).transfers[t.transfer_id]
      return false unless t1.nil? and t2.nil?

      client_info(taker).chunk_info.transfer(url, chunkid..chunkid) 
      client_info(taker).transfers[t.transfer_id] = t
      client_info(giver).transfers[t.transfer_id] = t

      #send transfer message to the connector
      addr, port = t.acceptor.get_peer_info
      
      t.connector.send_message(:transfer,
        :host => addr,
        :port => t.acceptor.user_data.listen_port,
        :method => t.connector == t.taker ? "get" : "put",
        :url => url,
        :range => byte_range,
        :peer_id => client_info(t.acceptor).client_id
      )
      true
    end

    #this function removes all stalled transfers from the list
    #and spawns new transfers as appropriate
    #it must be called periodically by EventMachine
    def clear_all_stalled_transfers
      @connections.each { |connection| clear_stalled_transfers_for_client connection }  
      spawn_all_transfers
    end

    #removes all stalled transfers that this client is a part of
    def clear_stalled_transfers_for_client(client_connection)
      client_info(client_connection).get_stalled_transfers.each do |transfer|
        transfer_completed transfer, client_connection, nil, false
      end  
    end

    #spawns uploads and downloads for this client.
    #should be called every time there is a change that would affect 
    #what this client has or wants
    def spawn_transfers_for_client(client_connection)
      info = client_info client_connection

      while info.wants_download? do
        break if spawn_download_for_client(client_connection) == false
      end

      while info.wants_upload? do
        break if spawn_upload_for_client(client_connection) == false
      end
    end

    #creates a single download for the specified client
    #returns true on success, false on failure
    def spawn_download_for_client(client_connection)
      feasible_peers=[]

      c1info=client_info(client_connection)
      begin
        url,chunkid=c1info.chunk_info.high_priority_chunk
      rescue
        return false
      end

      @connections.each do |c2|
        next if client_connection==c2
        next if client_info(c2).wants_upload? == false
        if client_info(c2).chunk_info.provided?(url,chunkid)
          feasible_peers << c2
          break if feasible_peers.size > 5
        end
      end

      # we now have a list of clients that have the requested chunk.
      # pick one and start the transfer
      if feasible_peers.size > 0
        #FIXME base this on the trust model
        giver=feasible_peers[rand(feasible_peers.size)]
        return begin_transfer(client_connection,giver,url,chunkid)
        #FIXME should we try again if begin_transfer fails?
      end

      false
    end

    #creates a single upload for the specified client
    #returns true on success, false on failure
    def spawn_upload_for_client(client_connection)
      c1info=client_info(client_connection)

      @connections.each do |c2|
        next if client_connection==c2
        next if client_info(c2).wants_download? == false

        begin
          url,chunkid=client_info(c2).chunk_info.high_priority_chunk
        rescue
          next
        end

        if c1info.chunk_info.provided?(url,chunkid)
          return begin_transfer(c2,client_connection,url,chunkid)
        end
      end

      false
    end

    #called by pdtp_protocol for each message that comes in from the wire
    def dispatch_message(command, message, connection)
      @stats_mutex.synchronize do
        dispatch_message_needslock command, message, connection
      end
    end

    #creates new transfers for all clients that have been updated
    def spawn_all_transfers
      while @updated_clients.size > 0 do
        tmp=@updated_clients
        @updated_clients=Hash.new
        tmp.each do |client,true_key| 
          spawn_transfers_for_client(client)
        end
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
      @updated_clients[connection]=true #add to the list of client that need new transfers
    end

    #handles all incoming messages from clients
    def dispatch_message_needslock(command, message, connection)
      # store the command in the message hash
      message["type"] = command
      
      #require the client to be logged in with a client id
      if command != "client_info" and client_info(connection).client_id.nil?
        raise ProtocolError.new("You need to send a 'client_info' message first")
      end 

      case command
      when "client_info"
        cid = message["client_id"]
        #make sure this id isnt in use
        if @used_client_ids[cid]
          raise ProtocolError.new("Your client id: #{cid} is already in use.")   
        end
        
        @used_client_ids[cid] = true 
        client_info(connection).listen_port = message["listen_port"]
        client_info(connection).client_id = cid
      when "ask_info"
        info = file_service.get_info(message["url"])
        response = { :url => message["url"] }
        unless info.nil?
          response[:size] = info.file_size
          response[:chunk_size] = info.base_chunk_size
          response[:streaming] = info.streaming
        end
        connection.send_message :tell_info, response
      when "request", "provide", "unrequest", "unprovide"
        handle_requestprovide connection, message
      when "ask_verify"
        #check if the specified transfer is a real one
        my_id = client_info(connection).client_id
        transfer_id=Transfer.gen_transfer_id(my_id,message["peer_id"],message["url"],message["range"])
        ok = !!client_info(connection).transfers[transfer_id]
        client_info(connection).transfers[transfer_id].verification_asked=true if ok
        @@log.debug "AskVerify not ok: id=#{transfer_id}" unless ok
        connection.send_message(:tell_verify,
          :url     => message["url"],
          :peer_id => message["peer_id"],
          :range   => message["range"],
          :peer    => message["peer"],
          :is_authorized=>ok
        )
      when "completed"
        my_id = client_info(connection).client_id
        transfer_id=  Transfer::gen_transfer_id(
          my_id,message["peer_id"],
          message["url"],
          message["range"]
        )
        transfer=client_info(connection).transfers[transfer_id]
        @@log.debug("Completed: id=#{transfer_id} ok=#{transfer != nil}" )
        if transfer
          transfer_completed(transfer,connection,message["hash"])
        else
          raise ProtocolWarn.new("You sent me a transfer completed message for unknown transfer: #{transfer_id}")
        end
      when 'protocol_error', 'protocol_warn' #ignore
      else raise ProtocolError.new("Unhandled message type: #{command}")
      end

      spawn_all_transfers
    end

    #returns a string representing the specified connection
    def connection_name(c)
      #host,port=c.get_peer_info
      #return "#{get_id(c)}: #{host}:#{port}"
      client_info(c).client_id
    end

    def generate_html_stats
      @stats_mutex.synchronize { generate_html_stats_needslock }
    end

    #builds an html page with information about the server's internal workings
    def generate_html_stats_needslock
      s = ERB.new <<EOF
<html><head><title>DistribuStream Statistics</title></head>
<body>
<h1>DistribuStream Statistics</h1>
Time=<%= Time.new %><br> Connected Clients=<%= @connections.size %>
<center><table border=1>
<tr><th>Client</th><th>Transfers</th><th>Files</th></tr>
<% @connections.each do |c| %>
  <tr><td>
  <% host, port = c.get_peer_info %>
  <%= connection_name(c) %><br><%= host %>:<%= port %>
  </td>
  <td>
  <%
  client_info(c).transfers.each do |key,t|
    if c==t.giver
      type="UP: "
      peer=t.taker
    else
      type="DOWN: "
      peer=t.giver
    end
    %>
    <%= type %> id=<%= t.transfer_id %><br>
    <%
  end
  %>
  </td>
  <td>
  <%
  client_info(c).chunk_info.get_file_stats.each do |fs|
    %>
    <%= fs.url %> size=<%= fs.file_chunks %> req=<%= fs.chunks_requested %>
    prov=<%= fs.chunks_provided %> transf=<%= fs.chunks_transferring %><br>    
    <%
  end      
  %>
  </td></tr>
  <%
end
%>
</table>
</body></html>
EOF
      s.result binding
    end
  end
end