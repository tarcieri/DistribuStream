require 'filemanager'

context "A FileManager with testfiles" do
	setup do
		@fman=FileManager.new
		@fman.set_root "../testfiles"
	end 
	
	specify "returns correct size for bla.txt" do
		info=@fman.get_info "/bla.txt"
		info.size.should_equal 7
	end
	
	specify "returns nil for files that dont exist" do
		info=@fman.get_info "/doesntexist.txt"
		info.should_equal nil
	end
	
end
	
