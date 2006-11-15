require File.dirname(__FILE__) + '/trust'
require File.dirname(__FILE__) + '/trust_graph'

context 'A new trust node' do
  setup do
    @node = Trust.new
    @other = Trust.new
    @distant = Trust.new
  end

  specify 'should be empty' do
    @node.outgoing.should_be_empty
    @node.implicit.should_be_empty
  end
  
  specify 'should trust a node after a good transfer' do
    @node.success(@other)
    @node.outgoing.should_not_be_empty
    @trust = @node.outgoing[@other].trust
  end
  
  specify 'should normalize trusts across outgoing edges' do
    @node.success(@distant)
    @node.outgoing.size.should == 2
    (@node.weight(other) + @node.weight(@distant)).should_be_close 1.0, 0.00001
  end
end