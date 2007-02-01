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

  def initialize *args
    super
    @@num_connections+=1
    user_data=nil
  end

  attr_accessor :user_data #users of this class may store arbitrary data here

  #override this in a child class to handle messages
  def receive_message message
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
    @@num_connections-=1
  end

  def PDTPProtocol::print_info
    puts "num_connections=#{@@num_connections}"
  end
end

