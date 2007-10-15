#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

module PDTP
  # Handle a memory buffer, which may be written to and read from randomly
  class MemoryBuffer
    def initialize
      @entries=Array.new
    end

    # Write data starting at start_pos. Overwrites any existing data in that block
    def write(start_pos, data)
      return if data.size==0
      # create and entry and attempt to combine it with old entries
      new_entry=Entry.new(start_pos,data)
      @entries.each do |e|
        union=combine(e,new_entry)
        if union
          @entries.delete(e)
          new_entry=union
        end 
      end

      # if we get here, it hasnt been combined with anything, so just add it
      @entries << new_entry
    end

    # Returns a string containing the desired data. 
    # Returns nil if the data is not all there
    def read(range)
      return nil if range.first>range.last
      current_byte=range.first

      buffer=String.new

      while current_byte <= range.last do
        # find an entry that contains this byte

        found=false
        @entries.each do |e|
          if e.range.include?(current_byte)

            internal_start=current_byte-e.start_pos #start position inside this entry's data
            internal_end=(range.last<e.end_pos ? range.last : e.end_pos) - e.start_pos 
            buffer << e.data[internal_start..internal_end]
            current_byte+=internal_end-internal_start+1
            found=true
            break if current_byte>range.last
          end
        end
        return nil if found==false
      end   
      return buffer
    end

    # Returns true if two entries intersect
    def intersects?(entry1, entry2)
      first,last=entry1,entry2
      first,last=last,first if last.start_pos<=first.start_pos
      return first.end_pos>=last.start_pos 
    end

    # Takes two Entries
    # Returns nil if there is no intersection
    # Returns the union if they intersect
    def combine(old,new)
      return nil unless intersects?(old,new)

      start= old.start_pos<new.start_pos ? old.start_pos: new.start_pos

      stringio=StringIO.new
      stringio.seek(old.start_pos-start)
      stringio.write(old.data)
      stringio.seek(new.start_pos-start)
      stringio.write(new.data)
      return Entry.new(start,stringio.string)    
    end

    # Return number of bytes currently in the buffer
    def bytes_stored
      bytes=0
      @entries.each do |e|
        bytes=bytes+e.data.size
      end  
      return bytes
    end

    # Container for an entry in the buffer
    class Entry
      def initialize(start_pos,data)
        @start_pos,@data=start_pos,data
      end

      attr_accessor :start_pos, :data

      def end_pos
        @start_pos+data.length-1
      end

      def range
        Range.new(@start_pos,end_pos)
      end
    end
  end
end