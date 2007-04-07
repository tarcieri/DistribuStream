require 'rubygems'
require 'eventmachine'
require 'thread'
require 'uri'
require 'ipaddr'

begin
  require 'fjson'
rescue Exception
  require 'json'
end


class ProtocolError < Exception
end

class ProtocolWarn < Exception
end

class PDTPProtocol < EventMachine::Protocols::LineAndTextProtocol
	@@num_connections=0
  @@listener=nil
  @@message_params=nil
  @connection_open=false

  def connection_open?
    return @connection_open
  end
  
  def PDTPProtocol::listener= listener
    @@listener=listener
  end
  
  def initialize *args
    user_data=nil
    @mutex=Mutex.new
    super
  end

  def post_init

    # a cache of the peer info because eventmachine seems to drop it before we want
    peername=get_peername
    if peername.nil? then
      @cached_peer_info="<Peername nil!!!>",91119 if peername.nil?
    else
      port,addr= Socket.unpack_sockaddr_in(peername)
      @cached_peer_info=[addr.to_s,port.to_i]
    end

    @@num_connections+=1
    @connection_open=true
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
      @@listener.dispatch_message(message,self) 
  end
   
  def receive_line line
    begin
      line.chomp!
			id = @@listener.get_id(self)
      @@log.debug("#{id} recv: "+line)
      message=JSON.parse(line)rescue nil
      raise ProtocolError.new("JSON couldn't parse: #{line}") if message.nil?

      PDTPProtocol::validate_message(message)
      
      hash_to_range(message)
      receive_message(message)

    rescue ProtocolError=>e
      @@log.warn("#{id} PROTOCOL ERROR: #{e.to_s}")
      @@log.debug(e.backtrace.join("\n"))
      error_close_connection(e.to_s)
    rescue ProtocolWarn=>e
      send_message( {"type"=>"protocol_warn", "message"=>e.to_s} )
    rescue Exception=>e
      puts "SERVER GOT UNKNOWN EXCEPTION #{e}"
      puts e.backtrace.join("\n")
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
    @connection_open=false
  end

  def PDTPProtocol::print_info
    puts "num_connections=#{@@num_connections}"
  end

  def get_peer_info
    return @cached_peer_info
  end

  def to_s
    addr,port = get_peer_info
    return "#{addr}:#{port}"
  end


  #makes sure that the message is valid.
  #if not, throws a ProtocolError
  def PDTPProtocol::validate_message(message)
    @@message_params||=define_message_params

    params=@@message_params[message["type"]] rescue nil
    raise ProtocolError.new("Invalid message type: #{message["type"]}") if params.nil?

    params.each do |name,type|
      if type.class==Optional then
        next if message[name].nil? #dont worry about it if they dont have this param
        type=type.type #grab the real type from within the optional class
      end

      raise ProtocolError.new("required parameter: '#{name}' missing for message type: '#{message["type"]}'") if message[name].nil?
      if !obj_matches_type?(message[name],type) then
        raise ProtocolError.new("parameter: '#{name}' val='#{message[name]}' is not of type: '#{type}' for message type: '#{message["type"]}' ")
      end

    end    

  end

  # an optional field of the specified type
  class Optional
    attr_accessor :type
    def initialize(type)
      @type=type
    end
  end

  #available types:
  # :url, :range, :ip, :int, :bool, :string
  def PDTPProtocol::obj_matches_type?(obj,type)
    case type
    when :url
      return obj.class==String
      #uri=URI::parse(obj) rescue nil
      #return uri ? true : false
    when :range
      return (obj.class==Range or obj.class==Hash)
    when :ip
      ip=IPAddr.new(obj) rescue nil
      return ip!=nil 
    when :int
      return obj.class==Fixnum
    when :bool
      return (obj==true or obj==false)
    when :string
      return obj.class==String
    else 
      raise "Invalid type specified: #{type}"
    end 
  end

  #this function defines the required fields for each message
  def PDTPProtocol::define_message_params
    mp={}

    #must be the first message the client sends
    mp["client_info"]={
      "client_id"=>:string,
      "listen_port"=>:int                  
    }
      
    mp["ask_info"]={
      "url"=>:url
    }

    mp["tell_info"]={
      "url"=>:url,
      "size"=>Optional.new(:int),
      "chunk_size"=>Optional.new(:int),
      "streaming"=>Optional.new(:bool)
    }

    mp["ask_verify"]={
      "peer"=>:ip,
      "url"=>:url,
      "range"=>:range,
      "peer_id"=>:string
    }

    mp["tell_verify"]={
      "peer"=>:ip,
      "url"=>:url,
      "range"=>:range,
      "peer_id"=>:string,
      "is_authorized"=>:bool
    }

    mp["request"]={
      "url"=>:url,
      "range"=>Optional.new(:range)
    }

    mp["provide"]={
      "url"=>:url,
      "range"=>Optional.new(:range)
    }

    mp["unrequest"]={
      "url"=>:url,
      "range"=>Optional.new(:range)
    }

    mp["unprovide"]={
      "url"=>:url,
      "range"=>Optional.new(:range)
    }

    #the taker sends this message when a transfer finishes
    #if there is an error in the transfer, dont set a hash
    #to signify failure
    #when this is received from the taker, the connection is considered done for all parties
    #
    #The giver also sends this message when they are done transferring.
    #this closes the connection on their side, allowing them to start other transfers
    #It leaves the connection open on the taker side to allow them to decide if the transfer was successful
    #the hash parameter is ignored when sent by the giver
    mp["completed"]={
      "peer"=>:ip,
      "url"=>:url,
      "range"=>:range,
      "peer_id"=>:string,
      "hash"=>Optional.new(:string)
    }

    mp["hash_verify"]={
      "url"=>:url,
      "range"=>:range,
      "hash_ok"=>:bool
    }

    mp["transfer"]={
      "host"=>:string,
      "port"=>:int,
      "method"=>:string,
      "url"=>:url,
      "range"=>:range,
      "peer_id"=>:string
    }  

    mp["protocol_error"]={
      "message"=>Optional.new(:string)
    }

    mp["protocol_warn"]={
      "message"=>Optional.new(:string)
    }

    return mp
  end

end

