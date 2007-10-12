#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

require File.dirname(__FILE__) + '/trust'

describe 'A new trust node' do
  before(:each) do
    @node = Trust.new
    @other = Trust.new
    @distant = Trust.new
  end

  it 'should be empty' do
    @node.outgoing.should be_empty
    @node.implicit.should be_empty
  end

  it 'should trust a node after a good transfer' do
    @node.success(@other)
    @node.outgoing.should_not be_empty
  end

  it 'should normalize trusts across outgoing edges' do
    @node.success(@other)
    trust = @node.weight(@other)

    @node.success(@distant)
    @node.outgoing.size.should == 2

    @node.weight(@other).should < trust
    (@node.weight(@other) + @node.weight(@distant)).should be_close(1.0, 0.00001)
  end
end
