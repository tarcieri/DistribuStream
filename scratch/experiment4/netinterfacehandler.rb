
class NetInterfaceHandler
	attr_accessor :net_interface
	
	def send(address,packet)
		@net_interface.send(address,packet,self)
	end	
	
	def dispatch(address,packet)
	end

end