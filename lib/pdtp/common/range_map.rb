#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
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

module PDTP
  # Structure which maps non-overlapping ranges to objects 
  class RangeMap
    include Enumerable
    
    def initialize
      @ranges = []
    end
    
    # Insert a range into the RangeMap
    def []=(range, obj)
      range = range..range if range.is_a?(Integer) or range.is_a?(Float)
      raise ArgumentError, 'key must be a number or range' unless range.is_a?(Range)
                
      index = binary_search range.begin
            
      # Correct total overlap
      [index, index + 1].each do |i|
        while @ranges[i] and @ranges[i][0].begin >= range.begin and @ranges[i][0].end <= range.end
          @ranges.delete_at i
        end
      end
        
      # Correct overlap with leftmost member
      if @ranges[index] and @ranges[index][0].begin <= range.begin
        if range.end < @ranges[index][0].end
          @ranges[index][0] = (range.end + 1)..(@ranges[index][0].end)
        else
          @ranges[index][0] = (@ranges[index][0].begin)..(range.begin - 1)
          index += 1
        end
      end
      
      # Correct overlap with rightmost member
      if @ranges[index] and @ranges[index][0].begin <= range.end
        @ranges[index][0] = (range.end + 1)..(@ranges[index][0].end)
      end
            
      # If adjacent entries map to the same object, combine them
      if @ranges[index] and @ranges[index][1] == obj and @ranges[index][0].begin - 1 == range.end
        range = (range.begin)..(@ranges[index][0].end)
        @ranges.delete_at index
      end
      
      if index > 0 and @ranges[index - 1][1] == obj and @ranges[index - 1][0].end + 1 == range.begin
        range = (@ranges[index - 1][0].begin)..(range.end)
        @ranges.delete_at index - 1
        index -= 1
      end
      
      @ranges.insert(index, [range, obj])
      obj
    end
    
    # Find a value in the RangeMap
    def [](value)
      return nil if empty?
      range, obj = @ranges[binary_search(value)]
      return nil if range.nil?
      
      case value
      when Integer, Float
        return nil unless range.include?(value)
      else raise ArgumentError, 'key must be a number'
      end
      
      obj
    end
    
    # Iterate over all ranges and objects
    def each(&block)
      @ranges.each(&block)
    end
            
    # Number of entries in the RangeMap
    def size
      @ranges.size
    end
    
    # First range
    def first
      @ranges.first[0]
    end
    
    # Last range
    def last
      @ranges.last[0]
    end
    
    # Is the RangeMap empty?
    def empty?
      @ranges.empty?
    end
    
    # Remove all elements from the RangeMap
    def clear
      @ranges.clear
      self
    end
    
    # Inspect the RangeMap
    def inspect
      "#<PDTP::RangeMap {#{@ranges.map { |r| "#{r.first}=>#{r.last.inspect}" }.join(", ")}}>"
    end
    
    #########
    protected
    #########
    
    # Find the index of the range nearest the given value
    def binary_search(value, a = 0, b = @ranges.size)
      pivot = (a + b) / 2          
      range, _ = @ranges[pivot]
      
      return b if range.nil?
      
      if value < range.begin
        return a if a == pivot
        binary_search(value, a, pivot) 
      elsif value > range.end
        return b if b == pivot
        binary_search(value, pivot + 1, b)
      else
        pivot
      end
    end    
  end
end