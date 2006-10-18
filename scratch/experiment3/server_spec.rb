require 'server'

context "A new server" do

	setup do
		@server=Server.new
	end

	specify "should register client" do
		client1="client1"
		@server.register_client(client1)
		@server.should_be_registered(client1)
  end

end

context "A server with clients connected" do
	setup do
		@server=Server.new
		@client1="client1"
		@server.register_client(@client1)
	end

	specify "responds correctly to askinfo" do
		request={
			:type => :askinfo,
			:filename => "bla.txt"
		}
	
		ret=@server.dispatch(@client1,request)
		ret[:type].should_equal :tellinfo
		ret[:filename].should_equal "bla.txt"
	end

	specify "throws exception on invalid packet" do
		request1="hello"
		request2={:type => :this_doesnt_exist}

		lambda{@server.dispatch(@client1,request1)}.should_raise RuntimeError
		lambda{@server.dispatch(@client1,request2)}.should_raise RuntimeError
	end

	specify "accepts transfer_status packet" do
		request={
			:type => :transfer_status
		}

		ret=@server.dispatch(@client1,request)
		ret.should_equal nil
	end
end

