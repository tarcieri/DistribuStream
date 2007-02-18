
class FileInfo
  attr_accessor :file_size, :base_chunk_size, :streaming

  #number of chunks in the file
  def num_chunks
    return 0 if @file_size==0
    return (@file_size-1)/@base_chunk_size + 1  
  end

  #size of the specified chunk
  def chunk_size(chunkid) 
    raise "Invalid chunkid #{chunkid}" if chunkid<0 or chunkid>=num_chunks
    rem=@file_size % @base_chunk_size
    return (chunkid==num_chunks-1) ? rem : @base_chunk_size
  end

  #range of bytes taken up by this chunk in the entire file
  def chunk_range(chunkid)
    start_byte=chunkid*@base_chunk_size
    end_byte=start_byte+chunk_size(chunkid)-1
    return start_byte..end_byte
  end
  
  #returns the chunkid that contains the requested byte offset
  def chunk_from_offset(offset)
    raise "Invalid offset #{offset}" if offset<0 or offset>=@file_size
    return offset/@base_chunk_size
  end

  #returns a range of bytes local to a chunk given a range of bytes in the file
  # returns [chunk,internal_range]
  def internal_range(range)
    chunkid=chunk_from_offset(range.first)
    start=chunkid*@base_chunk_size
    irange=(range.first-start)..(range.last-start)
    raise "Invalid range #{range}" if irange.first<0 or irange.last>=chunk_size(chunkid)
    return [chunkid,irange]
  end

  #returns a string containing the data for this chunk
  #range specifies a range of bytes local to this chunk
  #implemented in Client and Server file services
  def chunk_data(chunkid,range=nil)
  end

end

# base class for ClientFileService and ServerFileService.
# provides shared functionality

class FileServiceBase
  #returns a FileInfo class associated with the url, or nil if the file isnt known
  def get_info(url)
  end
end