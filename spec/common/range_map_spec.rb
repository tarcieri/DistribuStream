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

require File.dirname(__FILE__) + '/../../lib/pdtp/common/range_map'

describe PDTP::RangeMap do
  before :each do
    @map = PDTP::RangeMap.new
  end
  
  it "starts empty" do
    @map.should be_empty
  end
  
  it "provides hash-like behavior for integers" do
    # Sequential insertion test
    (0..9).step do |n|
      @map[n] = "item#{n}"
      
      # Revalidate all earlier members
      0.upto(n) do |i|
        @map[i].should == "item#{i}"
      end
      
      @map[n + 1].should be_nil
    end

    # Random insertion test
    [13, 19, 17, 15, 11, 18, 12, 14, 10, 16].each { |n| @map[n] = "item#{n}" }
    
    # Revalidate all earlier members
    0.upto(19) do |i|
      @map[i].should == "item#{i}"
    end
    
    @map[20].should be_nil
  end
  
  it "finds integers within a range" do 
    @map[0..1] = :foo
    @map[0].should == :foo
    @map[1].should == :foo
    @map[2].should be_nil
    
    @map[2..2] = :bar
    @map[0].should == :foo
    @map[1].should == :foo
    @map[2].should == :bar
    @map[3].should be_nil
    
    @map[10..20] = :baz
    @map[0].should == :foo
    @map[15].should == :baz
    @map[10].should == :baz
    @map[20].should == :baz
    @map[9].should be_nil
    @map[21].should be_nil
  end
  
  it "overrides earlier members when ranges overlap" do    
    # Right overlap test
    @map[0..1] = :foo
    @map[1..2] = :bar
    @map[0].should == :foo
    @map[1].should == :bar
    
    # Left overlap test
    @map[10..11] = :baz
    @map[9..10] = :quux
    @map[10].should == :quux
    
    # Sequential overlap test
    @map[20..22] = :a
    @map[21..23] = :b
    @map[22..24] = :c
    
    @map[20].should == :a
    @map[21].should == :b
    @map[22].should == :c
    
    # Eliminative right overlap test
    @map[30] = :x
    @map[31] = :y
    @map[30..31] = :z
    
    @map[30].should == :z
    @map[31].should == :z
  end
  
  it "deletes members which completely overlap others" do
    # Simple replacement
    @map[0] = :foo
    @map[0] = :bar
    @map[0].should == :bar
    @map.size.should == 1
    
    # Range replacement
    @map[0..1] = :a
    @map[0].should == :a
    @map.size.should == 1
    
    # Simple overlap checking
    @map[2..3] = :b
    @map[0..3] = :c
        
    (0..3).step { |n| @map[n].should == :c }
    @map.size.should == 1
    
    # Simple overlap checking on left
    @map.clear
    @map[0..2] = :a 
    @map[0] = :b
        
    @map[0].should == :b
    @map[1].should == :a
    @map[2].should == :a
    
    # Simple overlap checking on right
    @map.clear
    @map[0..2] = :a
    @map[2] = :b
    
    @map[0].should == :a
    @map[1].should == :a
    @map[2].should == :b
    
    # Complex overlap checking on right
    @map.clear
    @map[1..2] = :foo
    @map[2..3] = :bar
    @map[4..6] = :baz
    @map[0..5] = :quux
    
    (0..5).step { |n| @map[n].should == :quux}
    @map[6].should == :baz
    @map.size.should == 2
    
    # Complex overlap checking on left
    @map.clear
    @map[0..1] = :foo
    @map[2..3] = :bar
    @map[3..4] = :baz
    @map[1..4] = :quux
    
    (1..4).step { |n| @map[n].should == :quux}
    @map[0].should == :foo
    @map.size.should == 2
  end
  
  it "combines adjacent ranges which map to the same object" do
    @map[1..2] = :foo
    @map[4] = :foo
    @map[3] = :foo
    
    @map.size.should == 1
    (1..4).step { |n| @map[n].should == :foo }
    
    @map[0] = :foo
    @map.size.should == 1
  end
  
  it "can clear its contents" do
    @map[1] = :a
    @map[2] = :b
    @map[3] = :c
    @map.size.should == 3
    
    @map.clear
    @map.size.should == 0
  end
end
