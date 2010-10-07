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

require File.dirname(__FILE__) + '/../../lib/pdtp/common/length_prefix_protocol'

describe PDTP::LengthPrefixProtocol::Prefix do
  it "supports 2 or 4-byte prefixes" do
    proc { [2,4].each { |n| PDTP::LengthPrefixProtocol::Prefix.new(n) } }.should_not raise_error
  end
  
  it "raises an exception if instantiated with an invalid prefix size" do
    proc { PDTP::LengthPrefixProtocol::Prefix.new(3) }.should raise_error
  end
  
  it "uses a 2-byte prefix as the default" do
    PDTP::LengthPrefixProtocol::Prefix.new.size.should == 2
  end
  
  it "decodes 2-byte prefixes from network byte order" do
    @prefix = PDTP::LengthPrefixProtocol::Prefix.new(2)
    @prefix.append [42].pack('n')
    @prefix.payload_length.should == 42
  end
  
  it "decodes 4-byte prefixes from network byte order" do
    @prefix = PDTP::LengthPrefixProtocol::Prefix.new(4)
    @prefix.append [42].pack('N')
    @prefix.payload_length.should == 42
  end
  
  it "allows the prefix to be written incrementally" do
    @prefix = PDTP::LengthPrefixProtocol::Prefix.new(2)
    value = [42].pack('n')
    
    @prefix.append value[0..0]
    @prefix.read?.should be_false
    proc { @prefix.payload_length }.should raise_error
    
    @prefix.append value[1..1]
    @prefix.read?.should be_true
    @prefix.payload_length.should == 42
  end
  
  it "returns data which exceeds the prefix length" do
    @prefix = PDTP::LengthPrefixProtocol::Prefix.new(2)
    @prefix.append([42].pack('n') << "extra").should == 'extra'
  end
  
  it "resets to a consistent state after being used" do
    @prefix = PDTP::LengthPrefixProtocol::Prefix.new(2)
    @prefix.append [17].pack('n')
    
    @prefix.reset!
    @prefix.read?.should be_false
    proc { @prefix.payload_length }.should raise_error
    
    @prefix.append [21].pack('n')
    @prefix.payload_length.should == 21
  end
end

describe PDTP::LengthPrefixProtocol do
  before(:each) do
    @proto = PDTP::LengthPrefixProtocol.new nil
    @payload = "A test string"
  end
  
  it "decodes frames with 2-byte prefixes" do
    @proto.should_receive(:receive_packet).once.with(@payload)
    @proto.receive_data([@payload.length].pack('n') << @payload)
  end
  
  it "encodes frames with 2-byte prefixes" do
    @proto.should_receive(:send_data).once.with([@payload.length].pack('n') << @payload)
    @proto.send_packet(@payload)
  end
    
  it "decodes frames with 4-byte prefixes" do
    @proto.prefix_size = 4
    
    @proto.should_receive(:receive_packet).once.with(@payload)
    @proto.receive_data([@payload.length].pack('N') << @payload)
  end
  
  it "encodes frames with 4-byte prefixes" do
    @proto.prefix_size = 4
    
    @proto.should_receive(:send_data).once.with([@payload.length].pack('N') << @payload)
    @proto.send_packet(@payload)
  end
  
  it "reassembles fragmented frames" do
    msg1 = 'foobar'
    msg2 = 'baz'
    
    packet1 = [msg1.length].pack('n') << msg1
    packet2 = [msg2.length].pack('n') << msg2
    
    @proto.should_receive(:receive_packet).once.with(msg1)
    @proto.should_receive(:receive_packet).once.with(msg2)
    
    chunks = []
    chunks[0] = packet1[0..0]
    chunks[1] = packet1[1..(packet1.size - 1)] << packet2[0..0]
    chunks[2] = packet2[1..(packet2.size - 1)]
    
    3.times { |n| @proto.receive_data chunks[n] }
  end
  
  it "allows on-the-fly switching of prefix size" do
    msg1 = 'foobar'
    msg2 = 'baz'
    
    packet1 = [msg1.length].pack('n') << msg1
    packet2 = [msg2.length].pack('N') << msg2
    
    @proto.should_receive(:receive_packet).once.with(msg1)
    @proto.should_receive(:receive_packet).once.with(msg2)
    
    chunk1 = packet1[0..(packet1.size - 1)] << packet2[0..0]
    chunk2 = packet2[1..(packet2.size - 1)]
    
    @proto.receive_data chunk1
    @proto.prefix_size = 4
    @proto.receive_data chunk2
  end

  it "raises an exception for overlength frames" do
    payload = 'X' * 65537
    proc { @proto.send_packet payload }.should raise_error
  end
end
