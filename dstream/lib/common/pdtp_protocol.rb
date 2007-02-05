require 'rubygems'
require 'eventmachine'

begin
  require 'fjson'
rescue Exception
  require 'json'
end

# needed to make json able to handle the Range class appropriately
class Range
  def to_json(*a)
    {
      'json_class'   => self.class.name,
      'data'         => [ first, last, exclude_end? ]
    }.to_json(*a)
  end

  def self.json_create(o)
    new(*o['data'])
  end
end

class PDTPProtocol < EventMachine::Protocols::LineAndTextProtocol
  @@num_connections=0
  @@listener=nil

  def PDTPProtocol::listener= listener
    @@listener=listener
  end
  
  def initialize *args
    super
    @@num_connections+=1
    user_data=nil
    @@listener.connection_created(self) if @@listener.respond_to?(:connection_created)
  end

  attr_accessor :user_data #users of this class may store arbitrary data here

  #override this in a child class to handle messages
  def receive_message message
    begin
      @@listener.dispatch_message(message,self) 
    rescue Exception=>e
      puts "message translator closing connection for exception: #{e}"
      puts "on line: #{e.backtrace[0]}"
      close_connection # protocol error
    end
  end
   
  def receive_line line
    begin
      puts "line:"+line
      line.chomp!
      message=JSON.parse(line)
      receive_message(message)
    rescue Exception
      puts "pdtp_protocol closed connection"
      close_connection #there was an error in parsing
    end
  end

  def send_message message
    outstr=JSON.unparse(message)+"\n"
    puts "sending: #{outstr}"
    send_data outstr  
  end

  def unbind
    puts "unbinding connection"
    @@num_connections-=1
    @@listener.connection_destroyed(self) if @@listener.respond_to?(:connection_destroyed)
  end

  def PDTPProtocol::print_info
    puts "num_connections=#{@@num_connections}"
  end

  def get_peer_info
    port,addr= Socket.unpack_sockaddr_in(get_peername)
    return addr.to_s,port.to_i
  end

  def to_s
    addr,port = get_peer_info
    return "#{addr}:#{port}"
  end

end

