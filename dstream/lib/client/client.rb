require File.dirname(__FILE__) + '/../common/message'

class Client < MessageClient
  def initialize(network_manager)
    @message_manager=MessageManager.new
    #@file_service=FileService.new
    @message_manager.from_address=self
    @network_manager=network_manager
    @message_manager.attach [self,network_manager] 
  end

  def get_file(path)

  end
end
