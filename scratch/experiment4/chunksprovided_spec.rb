require 'chunksprovided' 

context "A ChunksProvided object with some provided chunks" do
	setup do
		@cp=ChunksProvided.new
		@cp.provide("/bla.txt",0..5)
		@cp.provide("/stuff.txt",10..20)
	end
	
	specify "provides the correct chunks" do
		@cp.provides?("/bla.txt",0).should_equal true
		@cp.provides?("/bla.txt",5).should_equal true
		@cp.provides?("/stuff.txt",10).should_equal true		
	end

	specify "does not provide chunks that weren't specified" do
		@cp.provides?("/bla.txt",6).should_equal false
		@cp.provides?("/stuff.txt",9).should_equal false
		@cp.provides?("doesntexist",0).should_equal false
	end

	specify "does not provide chunks that are unprovided" do
		@cp.unprovide("/bla.txt",5..6)
		@cp.provides?("/bla.txt",5).should_equal false
		@cp.provides?("/bla.txt",6).should_equal false
		@cp.provides?("/bla.txt",4).should_equal true
	end

end
