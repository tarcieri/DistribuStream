class PeerRank
	class Peer
		attr_accessor :rank,:trusts
	end

	def initialize
		@peers={}
	end
	
	def set_rank(client,rank)
		peer=@peers[client]||=Peer.new
		peer.rank=rank
	end
	
	def set_trust(client1,client2,trust)
		peer=@peers[client1]
		peer.trusts||={}
		peer.trusts[client2]=trust
	end
	
	def get_trust(client1,client2)
		return 1 if client1==client2
		return @peers[client1].trusts[client2] rescue 0
	end
	
	def iterate
		@peers.each do |key,val|
			sum=0
			
		end
	end
	
	def print
		@peers.each do |key,val|
			Kernel.print key,": pr=",val.rank," trusts: "
			val.trusts||={}
			val.trusts.each do |key,val|
				Kernel.print key,"=",val," "
			end
			puts
		end
	end

end

ranks=PeerRank.new
ranks.set_rank("c1",1)
ranks.set_rank("c2",1)
ranks.set_trust("c1","c2",3)
ranks.set_trust("c2","c1",1)
ranks.print