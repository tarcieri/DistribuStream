class ClientInfo
  attr_accessor :chunk_info
  
  def initialize
    @chunk_info=ChunkInfo.new
  end
 
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
    
protected
  def get(filename,chunk)
    return @files[filename][chunk] rescue :neither
  end

  def set(filename,range,state)
    chunks=@files[filename]||=Array.new
    range.each { |i| chunks[i]=state }
  end
end
