require 'transfer'

context "A new transfer" do
	setup do
		@client1="c1"
		@client2="c2"

		packet={
			:type => :transfer,
			:connector=> @client1,
			:listener=> @client2,
			:chunkid=> 10,
		}
		@transfer=Transfer.new(packet)
	end

	specify "can be created from a transfer packet" do

	end	

end
