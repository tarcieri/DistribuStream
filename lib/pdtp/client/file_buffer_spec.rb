#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

require File.dirname(__FILE__) + '/file_buffer'

describe PDTP::FileBuffer do
  before(:each) do
    @b = PDTP::FileBuffer.new
  end

  it "returns nil if read when empty" do
    @b.bytes_stored.should == 0
    @b.read(0..1).should == nil
  end  
end

describe PDTP::FileBuffer, "with one entry" do
  before(:each) do
    @b = PDTP::FileBuffer.new
    @b.write 0, 'hello'
  end

  it "calculates bytes stored correctly" do
    @b.bytes_stored.should == 5
  end

  it "reads stored data correctly" do
    @b.read(0..4).should == "hello"
    @b.read(1..1).should == "e"
    @b.read(-1..2).should == nil
    @b.read(0..5).should == nil
  end
end

describe PDTP::FileBuffer, "with two overlapping entries" do
  before(:each) do
    @b = PDTP::FileBuffer.new
    @b.write(3,"hello")
    @b.write(7,"World")
  end
  
  it "calculates bytes stored correctly" do
    @b.bytes_stored.should == 9
  end

  it "reads stored data correctly" do
    @b.read(3..12).should == nil
    @b.read(3..11).should == "hellWorld"
    @b.read(3..1).should == nil
    @b.read(2..4).should == nil
  end

end

describe PDTP::FileBuffer, "with three overlapping entries" do
  before(:each) do
    @b = PDTP::FileBuffer.new
    @b.write(3,"hello")
    @b.write(7,"World")
    @b.write(2,"123456789ABCDEF")
  end

  it "calculates bytes stored correctly" do
    @b.bytes_stored.should == 15
  end

  it "reads stored data correctly" do
    @b.read(2..16).should == "123456789ABCDEF"
    @b.read(2..17).should == nil
  end
end

describe PDTP::FileBuffer, "with two tangential entries" do
  before(:each) do
    @b = PDTP::FileBuffer.new
    @b.write(3,"hello")
    @b.write(8,"World")
  end

  it "calculates bytes stored correctly" do
    @b.bytes_stored.should == 10
  end
  
  it "reads stored data correctly" do
    @b.read(3..12).should == "helloWorld"
  end
end

describe PDTP::FileBuffer, "with a chain of overlapping entries" do
  before(:each) do
    @b = PDTP::FileBuffer.new
    @b.write(3,"a123")
    @b.write(4,"b4")
    @b.write(0,"012c")
  
    #___a123
    #___ab43
    #012cb43

  end

  it "calculates bytes stored correctly" do
    @b.bytes_stored.should == 7
  end

  it "reads stored data correctly" do
    @b.read(0..6).should == "012cb43"
    @b.read(3..6).should == "cb43"
  end
end

describe PDTP::FileBuffer, "with an associated IO object" do
  before(:each) do
    @io = mock(:io)
    @b = PDTP::FileBuffer.new @io
  end
  
  it "writes received data to the IO object" do
    @io.should_receive(:write).once.with('foo').and_return(3)
    @b.write(0, "foo")
  end
  
  it "writes successively received data to the IO object" do
    @io.should_receive(:write).once.with('foo').and_return(3)
    @b.write(0, "foo")
    
    @io.should_receive(:write).once.with('bar').and_return(3)
    @b.write(3, "bar")
    
    @io.should_receive(:write).once.with('baz').and_return(3)
    @b.write(6, "baz")
  end
  
  it "reassembles single-byte out-of-order data and writes it to the IO object" do
    @io.should_receive(:write).once.with('bar').and_return(3)
    @b.write(1, 'a')
    @b.write(2, 'r')
    @b.write(0, 'b')
  end
  
  it "reassembles multibyte out-of-order data and writes it to the IO object" do
    @io.should_receive(:write).once.with('foobar').and_return(6)
    @b.write(2, 'ob')
    @b.write(4, 'ar')
    @b.write(0, 'fo')
  end
end