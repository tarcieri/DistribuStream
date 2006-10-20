require 'server'
require 'testnetinterface'
require 'filemanager'

context "A Server with test files and a network interface" do
	setup do
		@server=Server.new
		@net=TestNetInterface.new
		@net.attach_handler(@server)
		@server.file_manager=FileManager.new
		@server.file_manager.set_root "../testfiles"
	end
	
	specify "responds to askinfo (file not found)" do
		request={
			:type=>:askinfo,
			:filename=>"/doesntexist.txt"
		}
		@net.send(@server,request)
		p=@net.packets[1].packet
		p[:type].should_equal :tellinfo
		p[:filename].should_equal "/doesntexist.txt"
		p[:status].should_equal :notfound
	end
	
	specify "responds to askinfo (file found)" do
		request={
			:type=>:askinfo,
			:filename=>"/bla.txt"
		}
		@net.send(@server,request)
		p=@net.packets[1].packet
		p[:type].should_equal :tellinfo
		p[:filename].should_equal "/bla.txt"
		p[:status].should_equal :normal
		p[:size].should_equal 7
	end
	

end
