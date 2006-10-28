require File.dirname(__FILE__) + '/server'
require File.dirname(__FILE__) + '/client'

context 'A server with a file service' do
  setup do
    @file_service = { "http://example.com/video.wmv" }
    @server = Server.new(@file_service)  
  end
  
  specify 'should serve chunks from the file service' do
    
  end
end

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

