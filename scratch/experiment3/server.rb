

class Server
	def initialize
		@clients={}
	end

	def register_client(address)
		@clients[address]=nil
	end

	def registered?(address)
		return @clients.has_key?(address)
	end


	def dispatch(address,packet)		

		handlers={ 
			:askinfo=> :dispatch_askinfo,
			:transfer_status => :dispatch_transfer_status
		}

		handler=handlers[ packet[:type] ]
		raise "Invalid packet" if handler==nil
		
		return method(handler).call(address,packet)
		
	end

	def dispatch_transfer_status(address,packet)
		return nil
	end

	def dispatch_askinfo(address,packet)
		return {
			:type => :tellinfo,
			:filename => packet[:filename]
		}
	end	

end
