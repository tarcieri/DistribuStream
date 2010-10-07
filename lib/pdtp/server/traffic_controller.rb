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

module PDTP
  class Server
    # Manages peer-to-peer traffic
    class TrafficController
      def initialize(peers, file_service)
        @peers, @file_service = peers, file_service
      end
      
      def schedule(client)
        while spawn_download(client); end
        #while spawn_upload(client); end
      end
      
      #######
      private
      #######
      
      # Find a peer to for the client to download from
      def spawn_download(client)
        return unless client.needs_download?
        
        file = client.next_download        
        return unless file and file.next_chunk
        
        possible_peers = @peers.map { |_, v| v }.select do |peer|
          client != peer and peer.needs_upload? and peer.providing? file.url, file.next_chunk 
        end
        
        peer = optimal_peer client, possible_peers
        byte_range = @file_service[file.url].byte_range file.next_chunk
        client.begin_download peer || @file_service, file.url, file.next_chunk, byte_range
        
        true
      end
      
      def optimal_peer(client, possible_peers)
        possible_peers.first
      end
      
      # Find a peer for the client to upload to
      def spawn_upload(peer)
        # FIXME stub!
      end
    end
  end
end