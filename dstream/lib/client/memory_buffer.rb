
class MemoryBuffer
  def initialize
    @entries=Array.new
  end

  def write(start_pos, data)
    new_entry=Entry.new(start_pos,data)
    @entries.each do |e|
      union=combine(e,new_entry)
      if union then
        @entries.delete(e)
        @entries << union
        return
      end 
    end

    #if we get here, it hasnt been combined with anything, so just add it
    @entries << new_entry
  end

  #returns a string containing the desired data
  #or nil if the data is not all there
  def read(range)
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


  def intersects?(entry1, entry2)
    first,last=entry1,entry2
    first,last=last,first if last.start_pos<=first.start_pos
    return first.end_pos>=last.start_pos 
  end

  #takes two Entries
  #returns nil if there is no intersection
  #returns the union if they intersect
  def combine(old,new)
    return nil unless intersects?(old,new)

    data=String.new
    start= old.start_pos<new.start_pos ? old.start_pos: new.start_pos
    data[old.start_pos-start..old.end_pos-start]=old.data
    data[new.start_pos-start..new.end_pos-start]=new.data
    return Entry.new(start,data)    
  end

  def bytes_stored
    bytes=0
    @entries.each do |e|
      bytes=bytes+e.data.size
    end  
    return bytes
  end

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
