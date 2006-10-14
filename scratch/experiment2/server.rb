

class ClientInfo

	attr_accessor :connection

end

class Server
	def initialize
		@clients={}
	end

	def connectionEvent(con)
		puts "server got connection event"
		client=@clients[con.object_id]
		if client==nil
			puts "new client connected"
			client=@clients[con.object_id]=ClientInfo.new
			client.connection=con
		end
		
		
		
		obj=con.recvObject
		puts "Got packet: "+obj.inspect
		return if obj.class!= Hash
		handlers={:request=>:handleRequest, :unrequest=>:handleUnrequest, :askinfo=>:handleAskInfo}
		
		handlerFunc=handlers[obj[:type]]
		return if handlerFunc==nil
		
		method(handlerFunc).call(obj,client)
		
	end
	
	def handleAskInfo(obj,client)
		puts "ask info packet received"
		packet={
			:type => :tellinfo,
			:filename => "bla.txt",
			:size => 410
		}
		client.connection.sendObject(packet)
	end

end

puts "running..."
server=Server.new

require "selectnetinterface"
netInterface=SelectNetInterface.new
netInterface.listen(8081)
netInterface.setEventListener(server)
netInterface.run


