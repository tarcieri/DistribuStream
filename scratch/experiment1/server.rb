require "netutil"
require "eventmachine"

class ClientInfo

	attr_accessor :connection

end

class Server
	def initialize
		@clients={}
	end

	def connectionEvent(con)
		client=@clients[con.object_id]
		if client==nil
			puts "new client connected"
			client=@clients[con.object_id]=ClientInfo.new
		end
		
		puts "got connection event"
		
		obj=con.recv
		return if obj.class!= Hash
		handlers={:request=>handleRequest, :unrequest=>handleUnrequest}
		
		handlerFunc=handlers[obj[:type]]
		return if handlerFunc==nil
		
		handlerFunc(obj,client)
		
	end

end

$server=Server.new

module ServerMarshalEMConnection
	include MarshalEMConnection
	
	def post_init
		@connectionListener=$server
	end
end


EventMachine::run do
	EventMachine::start_server "127.0.0.1", 8081, ServerMarshalEMConnection
end
