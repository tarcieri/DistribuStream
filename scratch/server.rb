require "socket"
require "yaml"


class Thinger
	def initialize(_str)
		@str=_str
	end
	
	def printstr
		puts @str
		puts "This is a thinger"
	end
end


class ChatServer
	def initialize(port)
		@descriptors=Array::new
		@serverSocket=TCPServer.new("",port)
		@serverSocket.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR,1)
		printf("Chatserver started on port %d\n",port);
		@descriptors.push(@serverSocket)
	end
	
	def run                 
		while 1 
			res=select(@descriptors,nil,nil,nil)
			redo if res==nil
			
			res[0].each do |sock|
				if sock==@serverSocket then
					acceptNewConnection
				else
					#got something from a client
					if sock.eof? then
						#str=sprintf("Client left %s:%s\r\n",sock.peeraddr[2],sock.peeraddr[1])
						str="Client left....\r\n"
						broadcastString(str,sock)
						sock.close
						@descriptors.delete(sock)
					else
						#str=sprintf("[%s|%s]: %s",sock.peeraddr[2],sock.peeraddr[1],sock.gets())
						#broadcastString(str,sock)
						obj=Marshal.load(sock)
						obj.printstr
					end
				end			 
			
			end
		
		end	
	end
	
	private
	
	def acceptNewConnection
		newsock=@serverSocket.accept
		@descriptors.push(newsock)
		name=sprintf("[%s|%s]",newsock.peeraddr[2],newsock.peeraddr[1])
		newsock.write("Welcome "+name+"\r\n")
		broadcastString("Client joined: "+name+"\r\n",newsock)
	end
	
	def broadcastString(str,omit)
		for sock in @descriptors 
			if (sock!=@serverSocket && sock!=omit)
				sock.write(str)
			end
		end
	end
	
end

server=ChatServer::new(8000)
server.run

		
