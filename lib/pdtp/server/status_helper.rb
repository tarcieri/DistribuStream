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
#
# Portions excerpted from ActionPack and released under the MIT license
# Copyright (c) 2004-2006 David Heinemeier Hansson
#
#++

module PDTP
  class Server
    # Helpers to be called from the DistribuStream status page ERb
    module StatusHelper
      # Number of clients presently connected
      def client_count
        clients = @status[:peers].size
        clients == 1 ? "1 client" : "#{clients} clients"
      end

      # Server's virtual host name
      def vhost
        @vhost
      end

      # Iterate over all available files
      def each_file(&block)
        @status[:files].each(&block)
      end
      
      # Iterate over all connected peers
      def each_peer(&block)
        @status[:peers].each(&block)
      end

      # Iterate over all of a peer's active transfers
      def each_transfer(peer)
        raise ArgumentError, "no block given" unless block_given?
        peer[:transfers].each { |_, transfer| yield transfer }
      end

      # Iterate over all of a peer's active files
      def each_peer_file(peer, &block)
        peer[:files].each(&block)
      end

      # Name of a peer (client ID or file service)
      def peer_name(peer)
        peer[:id]
      end
      
      # IP address and port of a peer
      def peer_address(peer)
        peer[:address]
      end
      
      # Upstream bandwidth of a peer
      def upstream_bandwidth(peer)
        bandwidth = peer[:upstream_bandwidth]
        return 'N/A' if bandwidth.nil?
        
        "#{bandwidth / 1024} kBps"
      end
      
      # Downstream bandwidth of a peer
      def downstream_bandwidth(peer)
        bandwidth = peer[:downstream_bandwidth]
        return 'N/A' if bandwidth.nil?
        
        "#{bandwidth / 1024} kBps"
      end

      # Information about an active transfer
      def transfer_info(peer, transfer)
        "#{peer == transfer.giver ? 'UP' : 'DOWN'}: id=#{transfer.transfer_id.split('$')[2..3].join(':')}"
      end

      # URL to a file
      def file_url(file)
        file[:url]
      end
      
      # Size of a file
      def file_size(file)
        size = file[:size].to_f
        case
        when size.to_i == 1;   "1 Byte"
        when size < 1024;      "%d Bytes" % size
        when size < 1024 ** 2; "%.1f KB"  % (size / 1024)
        when size < 1024 ** 3; "%.1f MB"  % (size / 1024 ** 2)
        else                   "%.1f GB"  % (size / 1024 ** 3)
        end.sub(/([0-9])\.?0+ /, '\1 ' )
      #rescue
      #  nil
      end
      
      def file_downloaders(file)
        file[:downloaders]
      end
      
      def file_uploaders(file)
        file[:uploaders]
      end
      
      # Number of requested chunks that have been completed
      def chunks_completed(file)
        file.chunks_provided
      end
      
      # Number of requested or completed chunks
      def chunks_active(file)
        file.file_chunks
      end
      
      # Percent of a file that has been transferred
      def percent_complete(file)
        (chunks_completed(file).to_f / chunks_active(file) * 100).to_i
      end

      def cycle(first_value, *values)
        if (values.last.instance_of? Hash)
          params = values.pop
          name = params[:name]
        else
          name = "default"
        end
        values.unshift(first_value)

        cycle = get_cycle(name)
        if (cycle.nil? || cycle.values != values)
          cycle = set_cycle(name, Cycle.new(*values))
        end
        return cycle.to_s
      end

      def reset_cycle(name = "default")
        cycle = get_cycle(name)
        cycle.reset unless cycle.nil?
      end

      #######
      private
      #######
      
      class Cycle #:nodoc:
        attr_reader :values
        
        def initialize(first_value, *values)
          @values = values.unshift(first_value)
          reset
        end
        
        def reset
          @index = 0
        end

        def to_s
          value = @values[@index].to_s
          @index = (@index + 1) % @values.size
          return value
        end
      end
      

      def get_cycle(name)
        @_cycles = Hash.new unless defined?(@_cycles)
        return @_cycles[name]
      end

      def set_cycle(name, cycle_object)
        @_cycles = Hash.new unless defined?(@_cycles)
        @_cycles[name] = cycle_object
      end      
    end
  end
end
