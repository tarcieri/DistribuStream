require 'rubygems'
require 'eventmachine'

begin
  require 'fjson'
rescue Exception
  require 'json'
end

DEBUG_MODE=true

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

  def error_close_connection(error)
    
    if DEBUG_MODE then
      msg={"error"=>error}
      send_message msg 
      close_connection(true) # close after writing
    else
      close_connection
    end
  end


  #override this in a child class to handle messages
  def receive_message message
    begin
      @@listener.dispatch_message(message,self) 
    rescue Exception=>e
      @@log.warn("pdtp_protocol closing connection for exception: #{e}")
      @@log.warn("on line: #{e.backtrace[0]}")
      error_close_connection(e.to_s) # protocol error
    end
  end
   
  def receive_line line
    begin
      line.chomp!
      @@log.debug("recv: "+line)
      message=JSON.parse(line)
      array_to_range(message)
      receive_message(message)
    rescue Exception
      @@log.warn("pdtp_protocol closed connection (parse error)")
      error_close_connection("JSON parse error") #there was an error in parsing
    end
  end
  
  RANGENAME="chunk_range"

  def range_to_array(message)
    if message[RANGENAME] then
      message[RANGENAME] = [ message[RANGENAME].begin, message[RANGENAME].end ]
    end
  end

  def array_to_range(message)
    if message[RANGENAME] then
      message[RANGENAME]= message[RANGENAME][0]..message[RANGENAME][1]
    end
  end

  def send_message message
    range_to_array(message)
    outstr=JSON.unparse(message)+"\n"
    @@log.debug( "send: #{outstr.chomp}")
    send_data outstr  
  end

  def unbind
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

