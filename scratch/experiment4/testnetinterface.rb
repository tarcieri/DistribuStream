require 'netinterfacehandler'

class TestNetInterface

	#packets are of the form [ source,dest,packet]
	class Packet < Array
		def source
			self[0]
		end
		def dest
			self[1]
		end
		def packet
			self[2]
		end
	end
	
	def initialize
		reset
	end
	
	def reset
		@packets=[]
	end

	attr_accessor :packets
	
	def attach_handler(handler)
		@handler=handler
		handler.net_interface=self
	end
	
	def send(address,packet,caller=nil)
		packets.push Packet.new([caller,address,packet])
		address.dispatch(caller,packet) rescue nil
	end

end