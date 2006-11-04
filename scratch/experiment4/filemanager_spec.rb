require 'filemanager'

context "A FileManager with testfiles" do
	setup do
		@fman=FileManager.new
		@fman.set_root "../testfiles"
		@fman.set_chunksize 1
	end 
	
	specify "returns correct size for bla.txt" do
		info=@fman.get_info "/bla.txt"
		info.size.should_equal 7
	end

	specify "returns correct chunk count for bla.txt" do
		info = @fman.get_info "/bla.txt" 		
		info.chunks.should_equal 7
		@fman.set_chunksize 2
		info = @fman.get_info "/bla.txt"		
		info.chunks.should_equal 4
		@fman.set_chunksize 3
		info = @fman.get_info "/bla.txt"
		info.chunks.should_equal 3
		@fman.set_chunksize 4
		info = @fman.get_info "/bla.txt"
		info.chunks.should_equal 2
		@fman.set_chunksize 7
		info = @fman.get_info "/bla.txt"
		info.chunks.should_equal 1
		@fman.set_chunksize 8
		info = @fman.get_info "/bla.txt"
		info.chunks.should_equal 1
	end	

	specify "returns nil for files that dont exist" do
		info=@fman.get_info "/doesntexist.txt"
		info.should_equal nil
	end

	specify "sends correct data to message manager" do
		@fman.set_chunksize 1
		info = @fman.get_info "/bla.txt"
		info.chunks.times {|i| @fman.send_chunk("/bla.txt",i,0)}
		print "\n"
		@fman.set_chunksize 2
		info = @fman.get_info "/bla.txt"
		info.chunks.times {|i| @fman.send_chunk("/bla.txt",i,0)}
		print "\n"
		@fman.set_chunksize 3
		info = @fman.get_info "/bla.txt"
		info.chunks.times {|i| @fman.send_chunk("/bla.txt",i,0)}
		print "\n"		
		@fman.set_chunksize 4
		info = @fman.get_info "/bla.txt"
		info.chunks.times {|i| @fman.send_chunk("/bla.txt",i,0)}	
		print "\n"
		@fman.set_chunksize 7
		info = @fman.get_info "/bla.txt"
		info.chunks.times {|i| @fman.send_chunk("/bla.txt",i,0)}	
		print "\n"
		@fman.set_chunksize 8
		info = @fman.get_info "/bla.txt"
		info.chunks.times {|i| @fman.send_chunk("/bla.txt",i,0)}	
		print "\n"
	end
	
end
	
