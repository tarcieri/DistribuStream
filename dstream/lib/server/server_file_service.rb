require "uri"    
require "pathname"
require "digest/sha1"
require File.dirname(__FILE__)+'/../common/file_service_base.rb'    
    
class ServerFileInfo < FileInfo
  attr_accessor :path

  def chunk_data(chunkid,range=nil)
    begin
      range=0..chunk_size(chunkid)-1 if range==nil # full range of chunk if range isnt specified
      raise if range.first <0 or range.last>=chunk_size(chunkid)
      start=range.first+chunkid*@base_chunk_size 
      size=range.last-range.first+1 
      file=open( @path)
      file.pos=start
      return file.read(size)
    rescue
      return nil
    end
  end 
end

class ServerFileService < FileServiceBase

	attr_accessor :root

	def initialize     
		@root=""
	end

	def get_info(url)
		begin
		  info=ServerFileInfo.new
		  info.streaming=false
		  info.base_chunk_size=512
      info.path=get_local_path(url)
		  info.file_size=File.size?( info.path )
      return nil if info.file_size==0 or info.file_size==nil
		rescue
      return nil
    end
		return info
	end	
	
	def get_local_path(url)
		path=URI.split(url)[5]
    path=path[1..path.size-1] #remove leading /
		return (Pathname.new(@root) + path).to_s	
	end

  #def get_chunk_hash(url,chunk_id)
  #  return Digest::SHA1.hexdigest(get_chunk_data(url,chunk_id)) rescue nil
  #end

end
