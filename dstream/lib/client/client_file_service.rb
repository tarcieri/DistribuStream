require "uri"    
require "pathname"
require File.dirname(__FILE__)+'/../common/file_service_base.rb'
    
    
class ClientFileInfo < FileInfo
	attr_accessor :data #string containing the chunk data

  def chunk_data(chunkid,range=nil)
    begin
      range=0..chunk_size(chunkid)-1 if range==nil # full range of chunk if range isnt specified
      return data[chunkid][range]
    rescue
      return nil
    end
  end

  def set_chunk_data(chunkid,data)
    @data||=Array.new
    @data[chunkid]=data
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
