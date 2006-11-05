require File.dirname(__FILE__) + '/server'
require File.dirname(__FILE__) + '/client'
require File.dirname(__FILE__) + '/message'
require File.dirname(__FILE__) + '/fileservice' 
require File.dirname(__FILE__) + '/network_simulator'

PATH="/bla.txt"

context 'A server with a file service' do
  setup do
    #@file_service = { "http://example.com/video.wmv" }
    #@server = Server.new(@file_service)  
  end
  
  specify 'should serve chunks from the file service' do
        
  end
end

context "A server,FileService attached to a message manager" do
  setup do
    @server=Server.new
    @fs=FileService.new
    @mm=MessageManager.new( [@server,@fs] ) 
    @client1="client1"
  end

  specify "should respond to askinfo" do
    message=RequestPacket.new(@client1, { :type=>:ask_info, :path=>PATH } )
    response=ResponsePacket.new(@client1, { :type=>:tell_info, :path=>PATH } ) 
    @mm.post(message)
    @mm.get_message(ResponsePacket).should_equal response
  end

  specify "Should send transfer message when asked" do
    @server.start_transfer(@client1,@mm,:take,PATH,0)
    expected=ResponsePacket.new(@client1, { :type=>:transfer, :listener=>@mm, :mode=>:take, :path=>PATH, :chunkid=>0 } )     
    @mm.get_message(ResponsePacket).should_equal expected 

  end

end

=begin
context 'A simulated network with client and server (server has file service)' do
  setup do
    @network=NetworkSimulator.new

    @server=Server.new
    @server_fs=FileService.new
    @server_mm=MessageManager.new( [@server,@server_fs,@network] )
  
    @client=Client.new
    @client_mm=MessageManager.new( [@client,@network] )
  end

end
=end

=begin
context 'A server with one client' do
  setup do
    @file_service = :file_service
    @client = Client.new
    @server = Server.new(@file_service)
  end    
  
  specify 'should provide chunk in one client, one chunk case' do
    response = @server.dispatch(@client, :type => :request, :path => "/video.mov")
    response.should.equal(:type => :transfer, :client => @client, :path => "/video.mov", :peer => @file_service, :mode => :take, :chunk => 1)
  end
  
  specify 'should provide chunks in order, five chunk case' do
    response = @server.dispatch(@client, :type => :request, :path => "/video.mov")
    
    5.times do |i|
      response.should.equal(:type => :transfer, :path => "/video.mov", :client => @client, :peer => @file_service, :mode => :take, :chunk => i)
      response = @server.dispatch(@client, :type => :complete, :path => "/video.mov", :chunk => i)
    end
  end
end

context 'A server with two clients' do
  setup do
    @file_service = :file_service
    @clients = [ Client.new, Client.new ]
    @server = Server.new(@file_service)
  end    
  
  specify 'should provide chunks to clients from the file service, first come, first served' do
    response = @server.dispatch(@clients[0], :type => :request, :path => "/video.mov")
    
    3.times do |i|
      response.should.equal(:type => :transfer, :path => "/video.mov", :client => @clients[0], :peer => @file_service, :mode => :take, :chunk => i)
      response = @server.dispatch(@clients[0], :type => :complete, :path => "/video.mov", :chunk => i)     
    end
    
    reponse = @server.dispatch(@clients[1], :type => :request, :path => "/video.mov")
    3.times do |i|
      response.should.equal(:type => :transfer, :path => "/video.mov", :client => @clients[1], :peer => @clients[0], :mode => :take, :chunk => i)
      response = @server.dispatch(@clients[1], :type => :complete, :path => "/video.mov", :chunk => i)
      
      response.should.equal(:type => :transfer, :path => "/video.mov", :client => @clients[0], :peer => @file_service, :mode => :take, :chunk => i + 3)
      response = @server.dispatch(@clients[0], :type => :complete, :path => "/video.mov", :chunk => i + 3)
    end    
  end
end
=end

