require File.dirname(__FILE__)+'/../common/pdtp_protocol'

class ServerMessageTranslator < PDTPProtocol
  def initialize *args
    super
  end

  attr_accessor :user_info # users of this class may store user specific data here


  @@server=nil #reference to a server object to communicate with

  def ServerMessageTranslator::server= server
    @@server=server
  end

  def receive_message message
    begin
      case message["type"]
      when "ask_info"
        @@server.ask_info(self,message["url"])
      else
        raise
      end
    rescue 
      puts "message translator closing connection"
      close_connection # protocol error
    end
  end
 
end
