require File.dirname(__FILE__) + '/server'



context 'Server with no connections' do
  setup do
    @server = Server.new()
  end

  specify 'should return nil when asked to list its connections' do
    @server.connections.should_be_empty
  end
  
  specify 'should raise an exception for any transition' do
	@server.connection(0).should_raise
  end
end
