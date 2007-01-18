require "uri"    
require "pathname"
    
    
class FileInfo
	attr_accessor :size, :chunk_size, :streaming
end

class ServerFileService

	attr_accessor :root

	def initialize     
		@root=""
	end

	def get_info(url)
		p get_local_path(url)
		p Pathname.new(@root) + "/bla.txt"
		info=FileInfo.new
		info.streaming=false
		info.chunk_size=512
		info.size=File.size?( get_local_path(url) )
		return nil if info.size.nil?
		return info
	
	end	
	
	def get_local_path(url)
		path=URI.split(url)[5]
		return (Pathname.new(@root) + path).to_s	
	end
	
	
end