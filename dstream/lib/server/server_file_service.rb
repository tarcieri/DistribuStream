require "uri"    
require "pathname"
require "digest/sha1"    
    
class FileInfo
	attr_accessor :size, :chunk_size, :streaming
end

class ServerFileService

	attr_accessor :root

	def initialize     
		@root=""
	end

	def get_info(url)
		#p get_local_path(url)
		#p Pathname.new(@root) + "/bla.txt"
		info=FileInfo.new
		info.streaming=false
		info.chunk_size=512
		info.size=File.size?( get_local_path(url) )
		return nil if info.size.nil?
		return info
	
	end	
	
	def get_local_path(url)
		path=URI.split(url)[5]
    path=path[1..path.size-1] #remove leading /
		return (Pathname.new(@root) + path).to_s	
	end

  def get_chunk_data(url,chunk_id)
    begin
      chunk_size=get_info(url).chunk_size
      file=open( get_local_path(url) )
      file.pos=chunk_size*chunk_id
      buffer=file.read(chunk_size)
    rescue
      buffer=nil
    end
    return buffer
  end	

  def get_chunk_size(url,chunk_id)
    info=get_info(url)
    rem=info.size % info.chunk_size
    num_chunks=(info.size-rem)/info.chunk_size+1
    return rem if chunk_id==num_chunks-1
    return info.chunk_size
  end
  
  def get_chunk_hash(url,chunk_id)
    return Digest::SHA1.hexdigest(get_chunk_data(url,chunk_id)) rescue nil
  end

end
