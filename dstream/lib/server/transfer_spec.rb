require File.dirname(__FILE__) + '/transfer'

context 'A transfer object' do
  setup do
    @transfer = Transfer.new
  end

  specify 'should respond to all the state machine messages' do
    @transfer.execute_transition(:Transfer)
    @transfer.execute_transition(:Failed)
    @transfer.execute_transition(:Transfer)
    @transfer.execute_transition(:Connected)
    @transfer.execute_transition(:TransferSuccess)
    @transfer.execute_transition(:Finished)
    @transfer.execute_transition(:Transfer)
    @transfer.execute_transition(:Failed)
    @transfer.execute_transition(:Transfer)
    @transfer.execute_transition(:Connected)
    @transfer.execute_transition(:TransferFailure)
    @transfer.execute_transition(:Finished)
  end
  
  specify 'should not respond to other messages' do
    @transfer.execute_transition(:blah).should_instance_of NameError
  end
end

=begin
context 'A server with no connections' do
  setup do
    @server = Server.new()
  end

  specify 'should return nil when asked to list its connections' do
    @server.connections.should_be_empty
  end
  
  specify 'should raise an exception for any transition' do
    #@server.connection(0).should_throw :connection_not_found
  end
end

context 'A server with one or more connections' do
  setup do
    @server = Server.new()
    @server.add_connection(0)
  end

  specify 'should be able to find connections' do
    @server.connection(0).should_not_be_nil
  end

  specify 'should be able to perform state transitions for a connection' do
    @server.Transfer(0)
    puts @server.current_state(0)
  end
end
=end
