#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

require File.dirname(__FILE__)+"/file_service_base.rb"

describe "A FileInfo with chunk_size=1" do
  before(:each) do
    @fi=FileInfo.new
    @fi.file_size=5
    @fi.base_chunk_size=1
  end

  it "chunk_size works" do
    @fi.chunk_size(0).should == 1
    @fi.chunk_size(3).should == 1
    @fi.chunk_size(4).should == 1

    proc{ @fi.chunk_size(-1)}.should raise_error
    proc{ @fi.chunk_size(5)}.should raise_error        
  end

  it "num_chunks works" do
    @fi.num_chunks.should == 5
  end

  it "chunk_from_offset works" do
    @fi.chunk_from_offset(0).should == 0
    @fi.chunk_from_offset(4).should == 4
    proc{@fi.chunk_from_offset(5)}.should raise_error
  end

  it "chunk_range_from_byte_range works" do
    @fi.chunk_range_from_byte_range(0..4,false).should == (0..4)
    @fi.chunk_range_from_byte_range(0..4,true).should == (0..4)
    proc{@fi.chunk_range_from_byte_range(-1..3,true)}.should raise_error  
  end

end

describe "A FileInfo with chunk_size=256 and file_size=768" do
  before(:each) do
    @fi=FileInfo.new
    @fi.base_chunk_size=256
    @fi.file_size=768
  end  

  it "chunk_size works" do
    @fi.chunk_size(0).should == 256
    @fi.chunk_size(2).should == 256
    proc{@fi.chunk_size(3)}.should raise_error
  end

  it "num_chunks works" do
    @fi.num_chunks.should == 3
  end

  it "chunk_from_offset works" do
    @fi.chunk_from_offset(256).should == 1
    @fi.chunk_from_offset(255).should == 0
  end

  it "chunk_range_from_byte_range works" do
    @fi.chunk_range_from_byte_range(256..511,true).should == (1..1)
    @fi.chunk_range_from_byte_range(256..511,false).should == (1..1)
    @fi.chunk_range_from_byte_range(255..512,true).should == (1..1)
    @fi.chunk_range_from_byte_range(255..512,false).should == (0..2)
  end
end

describe "A FileInfo with chunk_size=256 and file_size=255" do
  before(:each) do
    @fi=FileInfo.new
    @fi.base_chunk_size=256
    @fi.file_size=255
  end

  it "num_chunks works" do
    @fi.num_chunks.should ==1
  end

  it "chunk_from_offset works" do
    @fi.chunk_from_offset(254).should == 0
  end
end  
