
class Message
  def initialize(type=nil,data=nil)
    @type=type
    @data=data
  end

 
  #these are the only variables that external code should access
  attr_accessor :type,:data

  attr_accessor :sender,:handled
end

class MessageManager
  # mode=:keep, unhandled messages stay in the queue for testing
  # mode=:exception, unhandled messages trigger a runtime exception

  #should not be used, only available to MessageClient
  attr_accessor :queue

  class MessageInfo
    attr_accessor :message,:sender,:handled
  end

  def initialize(clients=[])
    @mode=:debug
    @clients=Array.new
    @queue=Array.new
    @debug_list=Array.new
    @handling=false
    attach(clients)
  end

  def attach(clients)
    clients.each do |c| 
      @clients.push(c)
      c.message_manager=self
    end
  end

  def post(message)
    @queue.push(message)
    handle_messages
  end

  def handle_messages
    return if @handling==true #only have one copy of handle_messages on the stack at once
    @handling=true
    while @queue.size>0 do
      msg=@queue[0]
      msg.handled=false
      @clients.each do |c|
        msg.handled=true if c.dispatch(msg)
      end      
      
      @debug_list.push(@queue[0]) if @mode==:debug
      @queue.delete_at(0)
    end
    @handling=false
  end 

  #returns the first message in the debug_list of the desired type (or the first message if type=nil)
  #the message is then deleted
  def get_message(type=nil)
    @debug_list.each_index do |i|
      if type==nil or @debug_list[i].type==type
        ret=@debug_list[i]
        @debug_list.delete_at(i)
        return ret
      end  
    end
    return nil
  end

end

class MessageClient

  attr_accessor :message_manager  

  #returns true if this is handled or false otherwise
  def dispatch(message)
  end

  def post(message)
    message.sender=self
    @message_manager.post(message)  
  end
end


