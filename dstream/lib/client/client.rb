#require File.dirname(__FILE__) + '/transfer_manager'

class Client
  attr_accessor :file_service

  def tell_info(url,info)
    @file_service.set_info(url,info)
  end
end
    
