require "stringio"

class MarshalBuffer
	def appendString(str)
		@buffer||=String.new
		@buffer=@buffer+str	
	end

	def readObject
		@buffer||=String.new
		io=StringIO.new(@buffer)
		obj=Marshal.load(io) rescue nil
		@buffer=@buffer[io.tell,@buffer.length-1] if obj
		return obj	
	end
end

module Connection

	def send(object) 
	end
	
	#returns the next object from this connection or nil if nothing is available
	def recv 
	end

end


module MarshalEMConnection 
	
	def post_init
		@mbuffer=MarshalBuffer.new
	end

	def receive_data data
		@mbuffer||=MarshalBuffer.new
		@mbuffer.appendString data
		@connectionListener.connectionEvent(self)
	end
	
	def recv
		@mbuffer||=MarshalBuffer.new
		return @mbuffer.readObject
	end
	
	def send(obj)
		send_data(Marshal.dump(obj))
	end

end

module ClientMarshalEMConnection
	include MarshalEMConnection
	
end

