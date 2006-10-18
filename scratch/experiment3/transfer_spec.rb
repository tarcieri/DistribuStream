

context "A new transfer" do
	setup do
		@client1="c1"
		@client2="c2"

		packet={
			:type => :transfer,
			:connector=> c1,
			:listener=> c2,
			:chunkid=> 10,
		}
		@transfer=Transfer.new(packet)
	end	

end
