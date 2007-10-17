module PDTP
  class FileBuffer
    def initialize(io)
      @io = io
      @entries = []
      @total_written = 0
    end
    
    def write(start_pos, data)
      if start_pos > @total_written
      elsif start_pos == @total written
      else
      else      
    end
  end
end