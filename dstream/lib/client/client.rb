#require File.dirname(__FILE__) + '/transfer_manager'

class Client
  attr_accessor :file_service

  def dispatch_message(message,connection) 
    case message["type"]
    when "tell_info"
      info=FileInfo.new
      info.size,info.chunk_size,info.streaming=message["size"],message["chunk_size"],message["streaming"]
      @file_service.set_info(message["url"],info)
    else  
      raise "unknown message type: #{message['type']} "
    end
  end

end
    
