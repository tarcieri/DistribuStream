#--
# Copyright (C) 2006-08 Medioh, Inc. (info@medioh.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.org/
#++

require File.dirname(__FILE__) + '/../../lib/pdtp/client/file_buffer'

describe PDTP::Client::FileBuffer do
  before(:each) do
    @b = PDTP::Client::FileBuffer.new
  end

  it "raises a runtime error if read when empty" do
    proc { @b.read(0..1) }.should raise_error
  end  
end

describe PDTP::Client::FileBuffer, "with one entry" do
  before(:each) do
    @b = PDTP::Client::FileBuffer.new
    @b.write 0, 'hello'
  end

  it "reads stored data correctly" do
    @b.read(0..4).should == "hello"
    @b.read(1..1).should == "e"
    proc { @b.read(0..5) }.should raise_error
  end
end

describe PDTP::Client::FileBuffer, "with two tangential entries" do
  before(:each) do
    @b = PDTP::Client::FileBuffer.new
    @b.write(3,"hello")
    @b.write(8,"World")
  end

  it "reads stored data correctly" do
    @b.read(3..12).should == "helloWorld"
  end
end

describe PDTP::Client::FileBuffer, "with two separated entries" do
  before(:each) do
    @b = PDTP::Client::FileBuffer.new
    @b.write(1, "foo")
    @b.write(7, "baz")
  end
  
  it "handles the insertion tangential chunks between separated entries" do
    @b.write(4, "bar")
    
    # Peek inside the implementation and make sure it's chunk-thunking correctly
    populated = @b.instance_eval { @populated }
    populated.size.should == 1
    populated.first.should == (1..9)
    
    # And just for good measure, make sure we get out what we expect
    @b.read(1..9).should == 'foobarbaz'
  end
end

describe PDTP::Client::FileBuffer, "with overlapping entries" do
  before(:each) do
    @b = PDTP::Client::FileBuffer.new
  end
  
  it "raises an exception when entries overlap" do
    @b.write(3,"foo")
    proc { @b.write(4,"bar") }.should raise_error
  end
end

describe PDTP::Client::FileBuffer, "with an associated IO object" do
  before(:each) do
    @io = mock(:io)
    @b = PDTP::Client::FileBuffer.new @io
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
