require File.dirname(__FILE__) + '/example'

context 'A server with no clients' do
    setup do
        @file_service = :file_service
        @client = Client.new
        @server = Server.new(@file_service)
    end    

    specify 'should provide chunk in one client, one chunk case' do
        response = @server.dispatch(@client, :type => :request)
        response.should.equal { :type => :transfer, :client => @client, :peer => @file_service, :mode => :take, :chunk => 1 }
    end
end

      
