#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

require 'rubygems'
require 'eventmachine'
require 'thread'
require 'uri'
require 'ipaddr'

begin
  require 'fjson'
rescue LoadError
  require 'json'
end

module PDTP
  PROTOCOL_DEBUG=true

  class ProtocolError < Exception
  end

  class ProtocolWarn < Exception
  end

  # EventMachine handler class for the PDTP protocol
  class Protocol < EventMachine::Protocols::LineAndTextProtocol
    @@num_connections = 0
    @@listener = nil
    @@message_params = nil
    @connection_open = false

    def connection_open?
      @connection_open
    end

    #sets the listener class (Server or Client)
    def self.listener=(listener)
      @@listener = listener
    end

    def initialize(*args)
      user_data = nil
      @mutex = Mutex.new
      super
    end

    #called by EventMachine after a connection has been established
    def post_init
      # a cache of the peer info because eventmachine seems to drop it before we want
      peername = get_peername
      if peername.nil?
        @cached_peer_info = ["<Peername nil!!!>", 91119] if peername.nil?
      else
        port, addr = Socket.unpack_sockaddr_in(peername)
        @cached_peer_info = [addr.to_s, port.to_i]
      end

      @@num_connections += 1
      @connection_open = true
      @@listener.connection_created(self) if @@listener.respond_to?(:connection_created)
    end

    attr_accessor :user_data #users of this class may store arbitrary data here

    #close a connection, but first send the specified error message
    def error_close_connection(error) 
      if PROTOCOL_DEBUG
        send_message :protocol_error, :message => msg 
        close_connection(true) # close after writing
      else
        close_connection
      end
    end

    #override this in a child class to handle messages
    def receive_message message
      @@listener.dispatch_message message, self 
    end

    #debug routine: returns id of remote peer on this connection
    def remote_peer_id
      ret = user_data.client_id rescue nil
      ret || 'NOID'
    end

    #called for each line of text received over the wire
    #parses the JSON message and dispatches the message
    def receive_line line
      begin
        line.chomp!
        @@log.debug "(#{remote_peer_id}) recv: " + line
        message = JSON.parse(line) rescue nil
        raise ProtocolError.new("JSON couldn't parse: #{line}") if message.nil?

        Protocol.validate_message message

        hash_to_range message
        receive_message message
      rescue ProtocolError => e
        @@log.warn "(#{remote_peer_id}) PROTOCOL ERROR: #{e.to_s}"
        @@log.debug e.backtrace.join("\n")
        error_close_connection e.to_s
      rescue ProtocolWarn => e
        send_message :protocol_warn, :message => e.to_s
      rescue Exception => e
        puts "(#{remote_peer_id}) UNKNOWN EXCEPTION #{e.to_s}"
        puts e.backtrace.join("\n")
      end
    end

    RANGENAMES = %w{chunk_range range byte_range}

    #converts Ruby Range classes in the message to PDTP protocol hashes with min and max
    # 0..-1 => nil  (entire file)
    # 10..-1 => {"min"=>10} (contents of file >= 10)
    def range_to_hash(message)
      message.each do |key,value|
        if value.class==Range
          if value==(0..-1)
            message.delete(key)
          elsif value.last==-1 
            message[key]={"min"=>value.first}
          else
            message[key]={"min"=>value.first,"max"=>value.last}
          end
        end   
      end
    end

    #converts a PDTP protocol min and max hash to a Ruby Range class
    def hash_to_range(message)
      key="range"
      auto_types=["provide","request"] #these types assume a range if it isnt specified
      auto_types.each do |type|
        if message["type"]==type and message[key].nil?
          message[key]={} # assume entire file if not specified
        end
      end

      if message[key]
        raise if message[key].class!=Hash
        min=message[key]["min"] 
        max=message[key]["max"]
        message[key]= (min ? min : 0)..(max ? max : -1)
      end
    end

    #sends a message, in the internal Hash format, over the wire
    def send_message(command, opts = {})
      message = opts.merge(:type => command.to_s)
        
      # Stringify all keys
      message = message.map { |k,v| [k.to_s, v] }.inject({}) { |h,(k,v)| h[k] = v; h }
      
      @mutex.synchronize do
        range_to_hash message
        outstr = JSON.unparse(message)+"\n"
        @@log.debug"(#{remote_peer_id}) send: #{outstr.chomp}"
        send_data outstr  
      end
    end

    #called by EventMachine when a connection is closed
    def unbind
      @@num_connections -= 1
      @@listener.connection_destroyed(self) if @@listener.respond_to?(:connection_destroyed)
      @connection_open=false
    end

    def self.print_info
      puts "num_connections=#{@@num_connections}"
    end

    #returns the ip address and port in an array [ip, port]
    def get_peer_info
      @cached_peer_info
    end

    def to_s
      addr,port = get_peer_info
      "#{addr}:#{port}"
    end

    #makes sure that the message is valid.
    #if not, throws a ProtocolError
    def self.validate_message(message)
      @@message_params||=define_message_params

      params=@@message_params[message["type"]] rescue nil
      raise ProtocolError.new("Invalid message type: #{message["type"]}") if params.nil?

      params.each do |name,type|
        if type.class==Optional
          next if message[name].nil? #dont worry about it if they dont have this param
          type=type.type #grab the real type from within the optional class
        end

        raise ProtocolError.new("required parameter: '#{name}' missing for message type: '#{message["type"]}'") if message[name].nil?
        if !obj_matches_type?(message[name],type)
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

    #returns whether or not a given ruby object matches the specified type
    #available types:
    # :url, :range, :ip, :int, :bool, :string
    def self.obj_matches_type?(obj,type)
      case type
      when :url then obj.class == String
      when :range then obj.class == Range or obj.class == Hash
      when :int then obj.class == Fixnum
      when :bool then obj == true or obj == false
      when :string then obj.class == String
      when :ip
        ip = IPAddr.new(obj) rescue nil
        !ip.nil?
      else 
        raise "Invalid type specified: #{type}"
      end 
    end

    #this function defines the required fields for each message
    def self.define_message_params
      mp = {}

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
        #"peer"=>:ip, no longer used
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

      mp
    end
  end
end