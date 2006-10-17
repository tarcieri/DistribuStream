require "socket"
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

#add some functions to make TCPSocket support the Connection interface
class TCPSocket
	def recvObject
		@mbuffer||=MarshalBuffer.new
		return @mbuffer.readObject
	end
	
	def sendObject(obj)
		write(Marshal.dump(obj))
	end
	
	#only called by the NetInterface
	def bufferIncomingData
		@mbuffer||=MarshalBuffer.new
		@mbuffer.appendString(self.readpartial(1000))
	end
	
	attr_accessor :userData #Server and client can store info in here

end

class SelectNetInterface
	def initialize
		@descriptors=Array::new
		#@descriptors.push(STDIN)
	end
	
	def listen(port)
		serverSocket=TCPServer.new("",port)
		serverSocket.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR,1)
		printf("listening on port %d\n",port);
		@descriptors.push(serverSocket)
	end
	
	def connect(host,port)
		newsock=TCPSocket.new(host,port)
		@descriptors.push(newsock)
		return newsock
	end
	
	def setEventListener(listener)
		@listener=listener
	end
	

	def run                 
		while 1 
			res=select(@descriptors,nil,nil,nil)
			redo if res==nil
			
			res[0].each do |sock|
				if sock.class==TCPServer then
					newsock=sock.accept
					@descriptors.push(newsock)
					name=sprintf("[%s|%s]",newsock.peeraddr[2],newsock.peeraddr[1])
					puts "Client joined: "+name
					#@listener.connectionEvent(sock)
				else
					#got something from a socket
					if sock.eof? then
						#str=sprintf("Client left %s:%s\r\n",sock.peeraddr[2],sock.peeraddr[1])
						#str="Client left....\r\n"
						#broadcastString(str,sock)
						#sock.close
						#@descriptors.delete(sock)
					else
						
						sock.bufferIncomingData
						@listener.connectionEvent(sock)
					end
				end			 
			
			end
		
		end	
	end
	
end
