
#provides information about a single file on the network
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
    if chunkid==num_chunks-1 then
      return @file_size-@base_chunk_size*chunkid 
    else
      return @base_chunk_size
    end
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
    return offset / @base_chunk_size
  end

  #takes a byte_range in the file and returns an equivalent chunk range
  #if exclude_partial is true, chunks that are not completely covered by the byte range are left out
  def chunk_range_from_byte_range(byte_range,exclude_partial=true)
    min=chunk_from_offset(byte_range.first)
    min+=1 if exclude_partial and byte_range.first > min*@base_chunk_size 
   
    max_byte=byte_range.last
    max_byte=@file_size-1 if max_byte==-1 or max_byte>=@file_size 
    max=chunk_from_offset(max_byte)
    max-=1 if exclude_partial and max_byte<chunk_range(max).last
    return min..max
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
