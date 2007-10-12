#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

require File.dirname(__FILE__) + "/memory_buffer.rb"

describe "A new memory buffer" do
  before(:each) do
    @mb=MemoryBuffer.new
  end

  it "has 0 bytes stored, read fails" do
    @mb.bytes_stored.should == 0
    @mb.read(0..1).should == nil
  end  
end

describe "A memory buffer with one entry" do
  before(:each) do
    @mb = MemoryBuffer.new
    @mb.write(0,"hello")
  end

  it "bytes_stored works" do
    @mb.bytes_stored.should == 5
  end

  it "read works" do
    @mb.read(0..4).should == "hello"
    @mb.read(1..1).should == "e"
    @mb.read(-1..2).should == nil
    @mb.read(0..5).should == nil
  end
end

describe "A memory buffer with two overlapping entries" do
  before(:each) do
    @mb=MemoryBuffer.new
    @mb.write(3,"hello")
    @mb.write(7,"World")
  end
  
  it "bytes_stored works" do
    @mb.bytes_stored.should == 9
  end

  it "read works" do
    @mb.read(3..12).should == nil
    @mb.read(3..11).should == "hellWorld"
    @mb.read(3..1).should == nil
    @mb.read(2..4).should == nil
  end

end

describe "A memory buffer with three overlapping entries" do
  before(:each) do
    @mb=MemoryBuffer.new
    @mb.write(3,"hello")
    @mb.write(7,"World")
    @mb.write(2,"123456789ABCDEF")
  end

  it "bytes_stored works" do
    @mb.bytes_stored.should == 15
  end

  it "read works" do
    @mb.read(2..16).should == "123456789ABCDEF"
    @mb.read(2..17).should == nil
  end
end

describe "A memory buffer with two touching entries" do
  before(:each) do
    @mb=MemoryBuffer.new
    @mb.write(3,"hello")
    @mb.write(8,"World")
  end

  it "bytes_stored works" do
    @mb.bytes_stored.should == 10
  end
  
  it "read works" do
    @mb.read(3..12).should == "helloWorld"
  end
end

describe "A memory buffer with a chain of overlapping entries" do
  before(:each) do
    @mb=MemoryBuffer.new
    @mb.write(3,"a123")
    @mb.write(4,"b4")
    @mb.write(0,"012c")
  
    #___a123
    #___ab43
    #012cb43

  end

  it "bytes_stored works" do
    @mb.bytes_stored.should == 7
  end

  it "read works" do
    @mb.read(0..6).should == "012cb43"
    @mb.read(3..6).should == "cb43"
  end
end
