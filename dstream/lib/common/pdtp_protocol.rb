require 'rubygems'
require 'eventmachine'

begin
  require 'fjson'
rescue Exception
  require 'json'
end

class PDTPProtocol < EventMachine::Protocols::LineAndTextProtocol
  @@num_connections=0

  def initialize *args
    super
    @@num_connections+=1
  end

  #override this in a child class to handle messages
  def receive_message message
  end
   
  def receive_line line
    begin
      line.chomp!
      message=JSON.parse(line)
      receive_message(message)
    rescue Exception
      close_connection #there was an error in parsing
    end
  end

  def send_message message
    outstr=JSON.unparse(message)+"\n"
    send_data outstr  
  end

  def unbind
    @@num_connections-=1
  end

  def PDTPProtocol::print_info
    puts "num_connections=#{@@num_connections}"
  end
end

