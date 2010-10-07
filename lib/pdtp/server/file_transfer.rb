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

require File.dirname(__FILE__) + '/../common/range_map.rb'

module PDTP
  class Server
    # Server's internal representation of a file transfer
    class FileTransfer
      attr_reader :url
      
      def initialize(url)
        @url = url
        @map = RangeMap.new
      end
      
      # Mark the given chunks as requested
      def request(range)
        @map[range] = :requested
      end
      
      # Is the given chunk requested?
      def requested?(chunk)
        @map[chunk] == :requested
      end
      
      # Mark the given chunks as provided
      def provide(range)
        @map[range] = :provided
      end
      
      # Is the given chunk provided?
      def provided?(chunk)
        @map[:chunk] == :provided
      end
      
      # Mark the given chunks as transferring
      def transferring(range)
        @map[range] = :transferring
      end
      
      # Don't do anything for the given chunks
      def clear(range)
        @map[range] = nil
      end
      
      def next_chunk
        range, _ = @map.find { |_, state| state == :requested }
        range.begin if range
      end
    end
  end
end
