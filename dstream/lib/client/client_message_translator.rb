require File.dirname(__FILE__)+'/../common/pdtp_protocol'

class ClientMessageTranslator < PDTPProtocol
  def initialize *args
    super
  end

  attr_accessor :user_info # users of this class may store user specific data here


  @@client=nil #reference to a server object to communicate with

  def ClientMessageTranslator::client= client
    @@client=client
  end

  def receive_message message
    begin
      case message["type"]
      when "tell_info"
        #@@client.ask_info(self,message["url"])
      else
        raise
      end
    rescue 
      close_connection # protocol error
    end
  end

  def unbind
    puts "connection lost"
  end
 
end
