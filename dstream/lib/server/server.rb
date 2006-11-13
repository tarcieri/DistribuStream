require File.dirname(__FILE__) + '/transfer_manager'
require File.dirname(__FILE__) + '/../common/message'

class Server
  def initialize(network_manager)
    @message_manager=MessageManager.new
    @message_manager.from_address=self #allows the network simulator to know where packets come from
    @transfer_manager=TransferManager.new
    @message_manager.attach [ network_manager, @transfer_manager ]
  end
end
    
