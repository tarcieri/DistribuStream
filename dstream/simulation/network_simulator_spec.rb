require File.dirname(__FILE__) + '/network_simulator'
require File.dirname(__FILE__) + '/../lib/common/message'

context "A network simulator" do
  setup do
    @sim=NetworkSimulator.new
    @mm1=MessageManager.new( [@sim] )
    @mm2=MessageManager.new( [@sim] )
  end

  specify "Should send a packet from one mm to another" do
    pack=ResponsePacket.new(@mm2,"hello")
    @mm1.post(pack)
    @mm2.get_message.should == RequestPacket.new(@mm1,"hello")

  end
end
