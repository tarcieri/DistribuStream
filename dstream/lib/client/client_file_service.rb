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
end
