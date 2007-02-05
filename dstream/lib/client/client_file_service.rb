require "uri"    
require "pathname"
    
    
class FileInfo
	attr_accessor :size, :chunk_size, :streaming
end

class ClientFileService
  class FileEntry
    attr_accessor :info,:chunks
  end

	def initialize     
		@files={}
	end

	def get_info(url)
    return @files[url].info rescue nil
	end	
	
  def set_info(url,info)
    file=@files[url]||=FileEntry.new
    file.info=info
  end

  def set_chunk_data(url,chunk_id,data)
    file=@files[url]||=FileEntry.new
    file.chunks||=Array.new
    file.chunks[chunk_id]=data 
  end

  def get_chunk_data(url,chunk_id)
    return @files[url].chunks[chunk_id] rescue nil  
  end

  def get_chunk_size(url,chunk_id)
    info=get_info(url)
    rem=info.size % info.chunk_size
    num_chunks=(info.size-rem)/info.chunk_size+1
    return rem if chunk_id==num_chunks-1
    return info.chunk_size
  end
end
