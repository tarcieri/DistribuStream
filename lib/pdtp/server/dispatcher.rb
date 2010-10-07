#--
# Copyright (C) 2006-08 Medioh, Inc. (info@medioh.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.org/
#++

require 'uri'
require File.dirname(__FILE__) + '/traffic_controller'

module PDTP
  class Server
    # Core dispatching and control logic for PDTP servers
    class Dispatcher
      attr_reader :peers
      
      def self.spawn(*args)
        new(*args).run
      end
      
      def initialize(server, file_service)
        @server, @file_service = server, file_service
        @peers = {}
        @traffic_controller = TrafficController.new(peers, file_service)
      end
      
      # Run the dispatcher
      def run
        Actor.spawn do
          loop do
            Actor.receive do |filter|
              filter.when(T[:peer_connect, Object]) do |_, peer|
                @server.log "client connected: #{peer.remote_host}:#{peer.remote_port}"
              end
              
              filter.when(T[:peer_closed, Object]) do |_, peer|
                @server.log "client disconnected: #{peer.remote_host}:#{peer.remote_port}"
                @peers.delete peer.client_id if peer.client_id
              end
              
              filter.when(T[:message, Object, Object, Object]) do |_, broker, peer, message|
                begin
                  dispatch_message peer, message
                  broker << :ok
                rescue => ex
                  broker << T[:error, ex]
                end
              end
              
              filter.when(T[:ask_status, Object]) { |_, actor| tell_status actor }
            end
          end
        end
      end
      
      #######
      private
      #######
      
      VALID_COMMANDS = %w{register ask_info request provide unrequest unprovide ask_verify completed}
      
      # Validate and dispatch an incoming command to the appropriate method
      def dispatch_message(peer, message)
        unless message.is_a? Array
          raise ProtocolError, "Message must be an Array"
        end
        
        unless message.size == 2
          raise ProtocolError, "Expected 2 members in root Array, found #{message.size}"
        end
        
        command, params = message
        
        unless VALID_COMMANDS.include? command
          raise ProtocolError, "invalid command: #{command}"
        end
        
        # Require the client to register their client id and listen port before doing anything
        if peer.client_id.nil? and command != "register" 
          raise ProtocolError, "Not registered (send a 'register' message)"
        end
        
        send("on_#{command}".intern, peer, params)
      end
      
      # Register a peer's client ID and listen port
      def on_register(peer, params = {})
        @server.debug "REGISTER: #{params.inspect}"
        
        raise ProtocolError, "client_id omitted in register message" unless params['client_id'] 
        raise ProtocolError, "listen_port omitted in register message" unless params['listen_port']
        
        id = params['client_id']
        raise ProtocolError, "client_id '#{id}' already in use." if @peers.include? id
        
        @peers[id] = peer 
        peer.instance_variable_set :@client_id, id
        peer.instance_variable_set :@listen_port, params['listen_port']
      end
      
      # Information request for a file
      def on_ask_info(peer, params = {})
        @server.debug "ASK INFO: #{params.inspect}"
        
        raise ProtocolError, "url omitted from ask_info message" unless params['url']
        
        uri = URI.parse params['url']
        raise ProtocolError, "invalid URI scheme: #{uri.scheme}" unless uri.is_a? URI::HTTP
        info = @file_service[uri.to_s]
        
        unless info
          peer.send_message :tell_info, :url => params['url'], :error => 'Not found'
          return
        end
        
        peer.send_message :tell_info, {
          :url        => params['url'], 
          :size       => info.size,
          :chunk_size => info.chunk_size,
          :streaming  => info.streaming
        }
      end
      
      # Incoming file transfer request
      def on_request(peer, params = {})
        on_transfer peer, :request, params
      end
      
      # Notification that a client possesses content
      def on_provide(peer, params = {})
        on_transfer peer, :provide, params
      end
      
      # Rescind a previous request
      def on_unrequest(peer, params = {})
        on_transfer peer, :unrequest, params
      end
      
      # Rescind a previous provide
      def on_unprovide(peer, params = {})
        on_transfer peer, :unprovide, params
      end
      
      # Common handler for all transfer request messages
      def on_transfer(peer, command, params = {})
        @server.debug "TRANSFER: #{command} #{params.inspect}"
        raise ProtocolError, "url omitted from request message" unless params['url']
        
        file_info = find_info(params['url'])
        return unless file_info
        
        if params['range']
          range = parse_range params['range'], file_info
        elsif [:request, :unrequest, :unprovide].include? command
          range = 0..(file_info.chunks - 1)
        else raise ProtocolError, "no range provided"
        end
        
        peer.update_transfer command, params['url'], range
        @traffic_controller.schedule(peer) if [:request, :provide].include? command
      end
      
      # Is the given transfer request authorized?
      def on_ask_verify(peer, params = {})
        @server.debug "ASK VERIFY: #{params.inspect}"
      end
      
      # Transfer complete
      def on_completed(peer, params = {})
        @server.debug "COMPLETED: #{params.inspect}"
                
        url = params['url']
        file_info = find_info url
        
        chunk_range = parse_range params['range'], file_info
        byte_range = params['range']
        peer_id = params['peer_id']
        transfer_id = ChunkTransfer.generate_id peer.client_id, peer_id, url, byte_range['min']..byte_range['max']
        
        unless (transfer = peer.chunk_transfers[transfer_id])
          return peer.send_error 'Invalid transfer', :url => url, :range => params['range'] 
        end
      
        remote_peer = (peer == transfer.connector ? transfer.acceptor : transfer.connector)
        unless params['peer'] == remote_peer.remote_addr
          return peer.send_error 'Invalid transfer', :url => url, :range => params['range']
        end 
        
        peer.transfer_complete file_info, transfer, params['hash']
        @traffic_controller.schedule(peer)
      end
      
      # Generate a representation of the current server state for the status page
      def tell_status(actor)
        status = {
          :files => @file_service.map do |url, info|
            {
              :url => url,
              :size => info.size,
              :downloaders => 0,
              :uploaders => 0
            }
          end,
          :peers => @peers.map do |_, peer|
            {
              :id => peer.client_id,
              :address => "#{peer.remote_host}:#{peer.remote_port}",
              :transfers => [],
              :files => []
            }
          end
        }

        actor << T[:tell_status, status]
      end
      
      # Locate the FileService::Info object for the given URL
      def find_info(url)
        uri = URI.parse url
        raise ProtocolError, "invalid URI scheme: #{uri.scheme}" unless uri.is_a? URI::HTTP
        
        unless (info = @file_service[uri.to_s])
          peer.send_error 'Not found', :url => uri.to_s
          return
        end
        
        info
      end
      
      # Parse a byte range and convert it to a chunk range
      def parse_range(range_hash, file_info)
        %w(min max).each do |k|
          unless range_hash[k].is_a? Integer
            raise ProtocolError, "invalid or missing #{k} chunk ID"
          end
        end
        
        range = range_hash['min']..range_hash['max']
        
        begin
          file_info.chunk_range_for_byte_range(range)
        rescue ArgumentError => ex
          raise ProtocolError, ex.to_s
        end
      end
    end
  end
end