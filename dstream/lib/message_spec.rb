require File.dirname(__FILE__)+"/message"

context "A MessageManager with nothing attached" do
  setup do
    @manager=MessageManager.new
    @m1=Message.new(:type1,"hi")
    @m2=Message.new(:type2,"hello")

  end

  specify "returns nil for get_message when no messages are available" do
    @manager.get_message.should_equal nil
    @manager.get_message(:some_type).should_equal nil
  end

  specify "returns first available message for get_message " do
    @manager.post(@m1)
    @manager.post(@m2)    
    @manager.get_message.should_equal @m1
    @manager.get_message.should_equal @m2
    @manager.get_message.should_equal nil
  end

  specify "returns first available message of correct type" do
    @manager.post(@m1)
    @manager.post(@m2)
    @manager.get_message(:type2).should_equal @m2
    @manager.get_message(:type2).should_equal nil
    @manager.get_message(:type1).should_equal @m1
    @manager.get_message.should_equal nil
  end 
    
end
