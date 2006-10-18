require 'client'
require 'server'

context "A new client" do
	setup do
		@client=Client.new
		
	end

	specify "can connect to a server" do
		@client.connect_server
	end
end
