#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

require "uri"    
require "pathname"
require File.dirname(__FILE__) + '/../common/file_service_base.rb'
require File.dirname(__FILE__) + '/memory_buffer.rb'    

# The client specific file utilities. Most importantly, handling
# the data buffer.
class ClientFileInfo < FileInfo

  # Write data into buffer starting at start_pos 
  def write(start_pos,data)
    @buffer||=MemoryBuffer.new
    @buffer.write(start_pos,data)
  end

  # Read a range of data out of buffer. Takes a ruby Range object
  def read(range)
    begin
      @buffer||=MemoryBuffer.new
      return @buffer.read(range)
    rescue
      return nil
    end
  end

  # Return the number of bytes currently stored
  def bytes_downloaded
    @buffer||=MemoryBuffer.new
    return @buffer.bytes_stored
  end

end

# Container class for file data
class ClientFileService < FileServiceBase

  def initialize
    @files = {}
  end

  def get_info(url)
    return @files[url] rescue nil
  end 

  def set_info(url,info)
    cinfo=ClientFileInfo.new
    cinfo.file_size=info.file_size
    cinfo.base_chunk_size=info.base_chunk_size
    cinfo.streaming=info.streaming
    @files[url]=cinfo
  end
end