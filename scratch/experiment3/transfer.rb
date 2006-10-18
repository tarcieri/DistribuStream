class Transfer
	def initialize(packet)
		@connector=packet[:connector]
		@listener=packet[:listener]
		@chunkid=packet[:chunkid]
		
	end

end
