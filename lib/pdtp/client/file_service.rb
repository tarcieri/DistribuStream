#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

require 'uri'
require 'pathname'
require File.dirname(__FILE__) + '/../common/file_service.rb'
require File.dirname(__FILE__) + '/file_buffer.rb'    

module PDTP
  class Client < Mongrel::HttpHandler
    # The client specific file utilities. Most importantly, handling
    # the data buffer.
    class FileInfo < PDTP::FileInfo
      def initialize(filename)
        @buffer = FileBuffer.new open(filename, 'w')
      end
      
      # Write data into buffer starting at start_pos 
      def write(start_pos,data)
        @buffer.write start_pos, data
      end

      # Read a range of data out of buffer. Takes a ruby Range object
      def read(range)
        begin
          @buffer.read range
        rescue nil
        end
      end

      # Return the number of bytes currently stored
      def bytes_downloaded
        @buffer.bytes_stored
      end
    end

    # Container class for file data
    class FileService < PDTP::FileService
      def initialize
        @files = {}
      end

      def get_info(url)
        @files[url] rescue nil
      end 

      def set_info(url, info)
        @files[url] = info
      end
    end
  end
end