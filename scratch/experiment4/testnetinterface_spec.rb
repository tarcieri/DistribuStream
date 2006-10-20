require 'testnetinterface'

context "A TestNetInterface" do
	specify "keeps track of sent packets" do
		iface=TestNetInterface.new
		iface.send("server","packet")
		p=iface.packets[0]
		p.packet.should_equal "packet"
		p.dest.should_equal "server"
	end
	
	specify "sends packets from handlers" do
		iface=TestNetInterface.new
		handler=NetInterfaceHandler.new
		iface.attach_handler(handler)
		handler.send("server","packet")
		iface.packets[0].should_equal [handler,"server","packet"]
	end


end