class ChunksProvided
	def initialize
		@files={}
	end

	def provide(filename,range)
		chunks=@files[filename]||=Array.new
		range.each { |i| chunks[i]=true }
	end

	def unprovide(filename,range)
		chunks=@files[filename]||=Array.new
		range.each { |i| chunks[i]=false }
	end

	def provides?(filename,chunk)
		return true if( @files[filename][chunk] rescue false == true)
		return false
	end

end
