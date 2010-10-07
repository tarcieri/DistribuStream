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

require 'digest/sha1'

module PDTP
  class Server
    # Server's internal representation of a chunk transfer
    class ChunkTransfer
      attr_reader :taker, :giver, :url, :chunk_id
      attr_reader :connector, :acceptor, :byte_range
      attr_accessor :transfer_id
      
      def self.generate_id(id1, id2, url, byte_range)
        a = id1 < id2 ? id1 : id2
        b = id1 < id2 ? id2 : id1
        Digest::SHA1.hexdigest "#{a}::#{b}::#{url}::#{byte_range}"
      end

      def initialize(taker, giver, url, chunk_id, byte_range, connector_receives = true)
        @taker, @giver, @url, @chunk_id, @byte_range = taker, giver, url, chunk_id, byte_range

        @verification_asked = false
        @creation_time = Time.now
        
        if connector_receives
          @connector = @taker
          @acceptor = @giver
        else
          @connector = @giver
          @acceptor = @taker
        end

        @transfer_id = ChunkTransfer.generate_id @connector.client_id, @acceptor.client_id, url, byte_range
      end
      
      # Has the acceptor asked the server to verify this transfer is valid?
      def verification_asked?; @verification_asked; end

      def to_s
        "taker=#{@taker}, giver=#{@giver}, connector=#{@connector}, acceptor=#{@acceptor}, url=#{@url}, chunk_id=#{@chunk_id} range=#{@byte_range}"
      end
    end
  end
end