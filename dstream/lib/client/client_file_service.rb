require "uri"    
require "pathname"
require File.dirname(__FILE__) + '/../common/file_service_base.rb'
    
    
#The client specific file utilities.
class ClientFileInfo < FileInfo
	#string containing the chunk data
	attr_accessor :data

  #Return a raw string of chunk data. The range parameter is local
	#to this chunk and is 0 based. That is, the first byte of every chunk
	#is represented by 0.
  def chunk_data(chunkid,range=nil)
    begin
		  # full range of chunk if range isnt specifiedn
      range=0..chunk_size(chunkid)-1 if range==nil
      return data[chunkid][range]
    rescue
      return nil
    end
  end

  #Set a raw string of chunk data. Data is assumed to take up the entire chunk
  def set_chunk_data(chunkid,data)
    @data ||= Array.new
    @data[chunkid] = data
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
