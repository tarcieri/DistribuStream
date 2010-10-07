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

require 'json'
require File.dirname(__FILE__) + '/file_transfer'
require File.dirname(__FILE__) + '/chunk_transfer'

module PDTP
  class Server
    # Server's internal representation of a client connection
    class Peer
      attr_reader :client_id
      
      # FIXME this really shouldn't be necessary
      attr_accessor :chunk_transfers
      
      def initialize(sock)
        @sock = sock
        
        # File transfers the client is participating in
        @file_transfers = {}
        
        # Chunk transfers the client is actively participating in
        @chunk_transfers = {}
        
        # Round-robin file transfer queue
        @transfer_queue = []
        
        # Port the client is listening on        
        @listen_port = nil
      end
      
      %w{remote_host remote_addr remote_port}.each do |meth|
        define_method(meth.intern) { @sock.__send__(meth) }
      end
      
      # Address prefix of this peer
      def prefix(mask = 24)
        raise ArgumentError, "mask must be 8, 16, or 24" unless [8, 16, 24].include?(mask)
        
        octets = mask / 8
        remote_addr.split('.')[0..(octets - 1)].join('.')
      end
      
      # Write the given message to the peer's socket
      def send_message(command, args = {})
        @sock.write [command, args].to_json
      end
      
      # Write an error message to the peer's socket
      def send_error(reason, params = {})
        send_message :error, params.merge(:reason => reason)
      end
      
      # Indicate a fatal protocol error and close the socket
      def fatal_error(reason, params = {})
        send_message :protocol_error, params.merge(:reason => reason)
      end 
      
      # Update the transfers a client is participating in
      def update_transfer(command, url, range)
        transfer = @file_transfers[url]
        
        unless transfer
          return send_error("Not active", :url => url) if [:unrequest, :unprovide].include? command
          transfer = FileTransfer.new(url)
          
          @file_transfers[url] = transfer
        end
        
        case command
        when :request
          transfer.request range
          @transfer_queue << transfer unless @transfer_queue.include? transfer
        when :transfer
          transfer.transferring range
        when :provide
          transfer.provide range
        when :unrequest, :unprovide
          transfer.clear range
        end
      end
      
      # URL and chunk ID of the next download the client needs
      def next_download
        begin
          file_transfer = @transfer_queue.shift
          return unless file_transfer
        end until file_transfer.next_chunk  
        
        @transfer_queue.push file_transfer
        file_transfer
      end
      
      # Begin downloading the given chunk of the given ID from the given peer
      def begin_download(peer, url, chunk_id, byte_range)
        puts "beginning download: (slots: #{empty_transfer_slots}) #{url} (#{byte_range})"
        
        transfer = ChunkTransfer.new self, peer, url, chunk_id, byte_range

        update_transfer :transfer, url, chunk_id
        @chunk_transfers[transfer.transfer_id] = transfer
        peer.chunk_transfers[transfer.transfer_id] = transfer

        transfer.connector.send_message(:transfer,
          :host => transfer.acceptor.remote_addr,
          :port => transfer.acceptor.listen_port,
          :method => transfer.connector == transfer.taker ? "get" : "put",
          :url => url,
          :range => {:min => byte_range.begin, :max => byte_range.end},
          :peer_id => transfer.acceptor.client_id
        )
      end
      
      # Called when a file transfer has been completed
      def transfer_complete(file_info, transfer, peer_hash)
        if self == transfer.giver and peer_hash
          raise ProtocolError, "unexpected hash parameter"
        end
        
        authoritative_hash = file_info.chunk_digest(transfer.chunk_id)
        @chunk_transfers.delete(transfer.transfer_id)
        return unless self == transfer.taker
        
        success = (peer_hash == authoritative_hash)
        #success ? transfer.success : transfer.failure
          
        self.send_message(:hash_verify, 
          :url => transfer.url, 
          :range => { :min => transfer.byte_range.begin, :max => transfer.byte_range.end }, 
          :hash_ok => success
        )
      end
      
      # Does the client need to download anything?
      def needs_download?
        return false if @transfer_queue.empty?        
        return false unless empty_transfer_slots?
                
        # Are we at our concurrent download limit?
        downloads.size < max_concurrent_downloads
      end
      
      # Does the client need to upload anything?
      def needs_upload?
        return false unless empty_transfer_slots?
        
        # Are we at our concurrent upload limit?
        uploads.size < max_concurrent_uploads
      end
      
      # Is the peer providing the given chunk?
      def providing?(url, chunk)
        file_transfer = @file_transfers[url]
        return unless file_transfer
        
        file_transfer.provided? chunk
      end
      
      # Number of concurrent downloads desired desired
      # FIXME hardcoded, should probably be computed or client-specified
      def max_concurrent_downloads; 8; end
      
      # For now, keep concurrent_downloads equal to uploads
      alias_method :max_concurrent_uploads, :max_concurrent_downloads
      
      # Maximum number of "half open" transfers allowed
      # FIXME hardcoded, should probably be computed
      def max_half_open; 8; end
      
      # Are we below the limit on half-open transfer slots? 
      def empty_transfer_slots?
        empty_transfer_slots > 0
      end
      
      # Number of empty transfer slots available
      def empty_transfer_slots
        max_half_open - @chunk_transfers.select { |_, t| not t.verification_asked? }.size 
      end
      
      # List of all active downloads
      def downloads
        @chunk_transfers.select { |_, t| t.taker == self and t.verification_asked? }
      end
      
      # List of all active uplaods
      def uploads
        @chunk_transfers.select { |_, t| t.giver == self and t.verification_asked? }
      end
    end
  end
end