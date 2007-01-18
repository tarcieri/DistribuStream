require "stringio"
require "socket"


class MarshalBuffer
	def append_string(str)
		@buffer||=String.new
		@buffer=@buffer+str	
	end

	def read_object
		@buffer||=String.new
		io=StringIO.new(@buffer)
		obj=Marshal.load(io) rescue nil
		@buffer=@buffer[io.tell,@buffer.length-1] if obj
		return obj	
	end
end

class NetworkManager

	class Connection
		attr_accessor :socket

		def initialize
			@mbuffer=MarshalBuffer.new
		end
		
		def send_message(message)
			socket.write(Marshal.dump(message))
		end

		def recv_message
			return @mbuffer.read_object
		end

		def buffer_incoming_data
			@mbuffer.append_string(socket.readpartial(100000))
		end
	end

	def initialize
		@descriptors=Array.new
		@listeners=Array.new
		@connections=Hash.new  #list of connections, keyed by the socket
	end
	
	def listen(port)
		serverSocket=TCPServer.new("",port)
		serverSocket.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR,1)
		printf("listening on port %d\n",port);
		@descriptors.push(serverSocket)
	end
	
	def connect(address,port)
		newsock=TCPSocket.new(address,port)
		@descriptors.push(newsock)
		return newsock
	end
	
	def register_message_listener(listener)
		@listeners<<listener
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
					
					#add a new connection
					newcon=Connection.new
					newcon.socket=newsock 
					@connections[newsock]=newcon
					
				else
					#got something from a socket
					if sock.eof? then
						#str=sprintf("Client left %s:%s\r\n",sock.peeraddr[2],sock.peeraddr[1])
						#str="Client left....\r\n"
						#broadcastString(str,sock)
						#sock.close
						#@descriptors.delete(sock)
						sprintf("Client left %s:%s\r\n",sock.peeraddr[2],sock.peeraddr[1])
						
					else
						
						con=@connections[sock]
						con.buffer_incoming_data
						while ( msg=con.recv_message ) != nil 
							
						end
						
						sock.bufferIncomingData
						@listener.connectionEvent(sock)
					end
				end			 
			
			end
		
		end	
	end
	
	def send_msg_to_listeners(message,connection)
		@listeners.each { |l| l.dispatch_message( message, connection ) }
	end
	
end

		
