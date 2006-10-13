require "netutil"
require "eventmachine"

class Server

	def connectionEvent(con)
		puts "got connection event"
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
