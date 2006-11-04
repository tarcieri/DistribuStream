require 'messagemanager'

class FileManager
	class Info
		attr_accessor :size
		attr_accessor :chunks
	end

	class Message
		attr_accessor :type
		attr_accessor :data
	end

	def set_root(root)
		@root = root
	end

	def set_chunksize(chunksize)
		@chunksize = chunksize
	end
	
	def get_info(filename)
		info = Info.new
		info.size = File.size?(@root+filename)
		return nil if info.size == nil
		info.chunks = info.size / @chunksize	
		info.chunks += 1 if  info.size % @chunksize != 0	
		return info
	end
	
	def send_chunk(filename, chunk, to)
		offset = chunk * @chunksize		
		str = File.read(@root+filename, @chunksize, offset)
		message = Message.new
		message.type = :chunk
		message.data = str
		MessageManager.send_message(to, message)
	end

end
