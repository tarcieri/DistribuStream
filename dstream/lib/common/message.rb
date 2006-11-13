
module BasicCompare
  def ==(obj)
    return instance_variables==obj.instance_variables
  end
end

class PacketIn
  include BasicCompare
  def initialize(source,data)
    @source,@data=source,data
  end
  attr_accessor :source,:data
end

class PacketOut
  include BasicCompare
  def initialize(dest,data)
    @dest,@data=dest,data
  end
  attr_accessor :dest,:data
end

class MessageManager

  class MessageInfo
    attr_accessor :msg,:sender,:handled
  end

   attr_accessor :from_address

  # mode=:keep, unhandled messages stay in the queue for testing
  # mode=:exception, unhandled messages trigger a runtime exception
  def initialize(clients=[])
    @mode=:debug
    @clients=Array.new
    @queue=Array.new
    @debug_list=Array.new
    @handling=false
    @from_address=self
    attach(clients)
  end

  def attach(clients)
    clients.each do |c|
      next if c.nil?
      @clients.push(c) 
      c.message_manager=self 
    end
  end

  def post(message,sender=nil)
    msg=MessageInfo.new
    msg.sender=sender
    msg.handled=false
    msg.msg=message
    @queue.push(msg)
    handle_messages
  end

  def handle_messages
    return if @handling==true #only have one copy of handle_messages on the stack at once
    @handling=true
    while @queue.size>0 do
      msg=@queue[0]
      msg.handled=false
      @clients.each do |c|
        msg.handled=true if c.dispatch_from(msg.msg,from_address)
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
      if type==nil or @debug_list[i].msg.class==type
        ret=@debug_list[i].msg
        @debug_list.delete_at(i)
        return ret
      end
    end
    return nil
  end

end

class MessageClient

  attr_accessor :message_manager

  #should be overridden by derived class
  #returns true if this is handled or false otherwise
  def dispatch(message)
  end

  #more informative version of dispatch for classes that need this
  def dispatch_from(message,src_manager)
    dispatch(message)
  end

  def post(message)
    @message_manager.post(message,self)
  end
end
