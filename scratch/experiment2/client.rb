class Client

	attr_accessor :netInterface #must be set by calling program

	def connectToServer(host,port)
		@serverConnection=netInterface.connect(host,port)
	end

	def connectionEvent(con)
		puts "got connection event"
		
		obj=con.recvObject
		return if obj.class!= Hash
		puts "Got packet: "+obj.inspect
		
	end
	
	def askFileInfo(filename)
		packet={
			:type => :askinfo,
			:filename => filename
		}
		puts packet.inspect
		@serverConnection.sendObject(packet)
	end

end

puts "client running..."

require "selectnetinterface"
netInterface=SelectNetInterface.new
client=Client.new
client.netInterface=netInterface
netInterface.setEventListener(client)

client.connectToServer("localhost",8081)
client.askFileInfo("bla.txt")

netInterface.run



