require "uri"    
require "pathname"
require File.dirname(__FILE__) + '/../common/file_service_base.rb'
require File.dirname(__FILE__) + '/memory_buffer.rb'    
    
#The client specific file utilities.
class ClientFileInfo < FileInfo

  def write(start_pos,data)
    @buffer||=MemoryBuffer.new
    @buffer.write(start_pos,data)
  end

  def read(range)
    begin
      @buffer||=MemoryBuffer.new
      return @buffer.read(range)
    rescue
      return nil
    end
  end
  
end


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
