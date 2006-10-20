class FileManager
	class Info
		attr_accessor :size
	end

	def set_root(root)
		@root=root
	end
	
	def get_info(filename)
		info=Info.new
		info.size=File.size?(@root+filename)
		return nil if info.size==nil
		return info
	end
	
	

end