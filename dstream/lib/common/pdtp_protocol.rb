require 'rubygems'
require 'eventmachine'
require 'thread'

begin
  require 'fjson'
rescue Exception
  require 'json'
end


class PDTPProtocol < EventMachine::Protocols::LineAndTextProtocol
	@@num_connections=0
  @@listener=nil

  def PDTPProtocol::listener= listener
    @@listener=listener
  end
  
  def initialize *args
    super
    user_data=nil
    @mutex=Mutex.new
  end

  def post_init
    @@num_connections+=1
    @@listener.connection_created(self) if @@listener.respond_to?(:connection_created)
  end

  attr_accessor :user_data #users of this class may store arbitrary data here

  def error_close_connection(error)
    
    if @@config.debug then
      msg={"type"=>"protocol_error","message"=>error}
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
      @@log.warn("backtrace:\n #{e.backtrace.join('\n')}\n")
      error_close_connection(e.to_s) # protocol error
    end
  end
   
  def receive_line line
    begin
      line.chomp!
			id = @@listener.get_id(self)
      @@log.debug("#{id} recv: "+line)
      message=JSON.parse(line)
      hash_to_range(message)
      receive_message(message)
    rescue Exception
      @@log.warn("pdtp_protocol closed connection (parse error)")
      error_close_connection("JSON parse error: #{line}") #there was an error in parsing
    end
  end
  
  RANGENAMES=["chunk_range","range","byte_range"]

  # 0..-1 => nil  (entire file)
  # 10..-1 => {"min"=>10} (contents of file >= 10)
  # 
  def range_to_hash(message)
    message.each do |key,value|
      if value.class==Range then
        if value==(0..-1) then
          message.delete(key)
        elsif value.last==-1 then
          message[key]={"min"=>value.first}
        else
          message[key]={"min"=>value.first,"max"=>value.last}
        end
      end   
    end
  end

  #throws an exception if any of the fields specified are not in the message
  def expect_fields(message,fields)
    fields.each do |f|
      raise "You didnt send a required field: #{f}" if message[f].nil?
    end
  end

  def hash_to_range(message)
    key="range"
    auto_types=["provide","request"] #these types assume a range if it isnt specified
    auto_types.each do |type|
      if message["type"]==type and message[key]==nil then
        message[key]={} # assume entire file if not specified
      end
    end
  
    if message[key] then
      raise if message[key].class!=Hash
      min=message[key]["min"] 
      max=message[key]["max"]
      message[key]= (min ? min : 0)..(max ? max : -1)
    end
  end

  def send_message message
    @mutex.synchronize do
      range_to_hash(message)
      outstr=JSON.unparse(message)+"\n"
			id = @@listener.get_id(self)
      @@log.debug( "#{id} send: #{outstr.chomp}")
      send_data outstr  
    end
  end

  def unbind
    @@num_connections-=1
    @@listener.connection_destroyed(self) if @@listener.respond_to?(:connection_destroyed)
  end

  def PDTPProtocol::print_info
    puts "num_connections=#{@@num_connections}"
  end

  def get_peer_info
    #puts "GETPEERNAME:#{ get_peername.inspect}"
    port,addr= Socket.unpack_sockaddr_in(get_peername)
    return addr.to_s,port.to_i
  end

  def to_s
    addr,port = get_peer_info
    return "#{addr}:#{port}"
  end

end

