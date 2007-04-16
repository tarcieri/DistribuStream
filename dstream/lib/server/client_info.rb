require File.dirname(__FILE__)+'/trust.rb'

class ClientInfo
  attr_accessor :chunk_info, :trust
  attr_accessor :listen_port, :client_id
  attr_accessor :transfers  

  # returns true if this client wants the server to spawn a transfer for it
  def wants_download?
    # allow 5 in the transferring state, and 50 in the connecting state
    transferring=0
    @transfers.each do |key,t|
      transferring=transferring+1 if t.verification_asked
      return false if transferring >= 5
    end
    
    return (@transfers.size < 10)
  end 

  def wants_upload?
    #this could have a different definition, but it works fine to use wants_download?
    return wants_download?
  end 
  
  def initialize
    @chunk_info=ChunkInfo.new
    @listen_port=6000 #default
    @trust=Trust.new
    @transfers=Hash.new
  end

  def get_stalled_transfers
    stalled=[]
    timeout=20.0
    now=Time.now
    @transfers.each do |key,t|
      if now-t.creation_time > timeout and t.verification_asked==false then
        stalled << t
      end
    end
    return stalled
  end

  #def clear_stalled_transfers
  #  timeout=2.0
  #  now=Time.now
  #  @transfers.delete_if { |key,t| 
  #    now - t.creation_time > timeout and t.verification_asked == false 
  #  }
  #end
 
end

class ChunkInfo
	def initialize
		@files={}
	end

  #each chunk can either be provided, requested, transfer, or none

  def provide(filename,range); set(filename,range,:provided) ; end
  def unprovide(filename,range); set(filename,range, :none); end
  def request(filename,range); set(filename,range, :requested); end
  def unrequest(filename,range); set(filename,range, :none); end
  def transfer(filename,range); set(filename,range, :transfer); end
  
  def provided?(filename,chunk); get(filename,chunk) == :provided; end
	def requested?(filename,chunk); get(filename,chunk) == :requested; end
 
  #returns a high priority requested chunk
  def high_priority_chunk
    #right now return any chunk
    @files.each do |name,file|
      file.each_index do |i|
        return [name,i] if file[i]==:requested
      end
    end  
    return nil
  end

  def each_chunk_of_type(type)
     @files.each do |name,file|
      file.each_index do |i|
        yield(name,i) if file[i]==type
      end
    end 
  end

  class FileStats
    attr_accessor :file_chunks, :chunks_requested,:url
    attr_accessor :chunks_provided, :chunks_transferring
    def initialize
      @url=""
      @file_chunks=0
      @chunks_requested=0
      @chunks_provided=0
      @chunks_transferring=0
    end
  end
  
  #returns an array of FileStats objects for debug output
  def get_file_stats
    stats=[]
    @files.each do |name,file|
      fs=FileStats.new
      fs.file_chunks=file.size
      fs.url=name
      file.each do |chunk|
        fs.chunks_requested+=1 if chunk==:requested
        fs.chunks_provided+=1 if chunk==:provided
        fs.chunks_transferring+=1 if chunk==:transfer
      end
      stats << fs
    end
    return stats 
  end
    
protected

  def get(filename,chunk)
    return @files[filename][chunk] rescue :neither
  end

  def set(filename,range,state)
    chunks=@files[filename]||=Array.new
    range.each { |i| chunks[i]=state }
  end

end
