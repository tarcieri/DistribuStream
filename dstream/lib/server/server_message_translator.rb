require File.dirname(__FILE__)+'/../common/pdtp_protocol'

class ServerMessageTranslator < PDTPProtocol
  def initialize *args
    super
  end

  @@server=nil #reference to a server object to communicate with

  def ServerMessageTranslator::server= server
    @@server=server
  end

  def receive_message message
    begin
      case message["type"]
      when "ask_info"
        @@server.ask_info(self,message["url"])
      when "request"
        @@server.request(self,message["url"],message["chunk_range"])
      else
        raise
      end
    rescue Exception=>e 
      puts "message translator closing connection for exception: #{e}"
      puts "on line: #{e.backtrace[0]}"
      close_connection # protocol error
    end
  end
 
end
