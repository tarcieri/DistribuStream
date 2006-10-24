require 'filemanager'
require 'netinterfacehandler'
require 'chunksprovided'

class ClientData
	def initialize
		@trusts={}
		@chunks_provided=ChunksProvided.new
	end

	attr_accessor :rank #global peer rank of this client
	attr_accessor :trusts #list of trust relationships between other clients
	attr_accessor :chunks_provided
	attr_accessor :address
end



class Server < NetInterfaceHandler
	attr_accessor :file_manager
	
	def initialize
		@clients={}
	end	

	def dispatch(address,packet)

		#find the client from the address.  Add a new client if they are just now connecting
		client=@clients[address]||=ClientData.new
		client.address=address
		
		handlers={ 
			:askinfo=> :dispatch_askinfo,
			:transfer_status => :dispatch_transfer_status,
			:request=>:dispatch_request,
			:provide=>:dispatch_provide,
			:unprovide=>:dispatch_provide
		}

		handler=handlers[ packet[:type] ]
		raise "Invalid packet" if handler==nil
		
		method(handler).call(client,packet)	
	end
	
	def dispatch_askinfo(client,packet)
		ret= {
			:type => :tellinfo,
			:filename => packet[:filename]
		}
		info=file_manager.get_info( packet[:filename])
		if info==nil 
			ret[:status]=:notfound
		else
			ret[:size]=info.size
			ret[:status]=:normal
		end
		
		send(client.address,ret)
	end	

	def dispatch_provide(client,packet)
		client.chunks_provided.provide(packet[:filename],packet[:range])
	end

	def dispatch_unprovide(client,packet)
		client.chunks_provided.unprovide(packet[:filename],packet[:range])	
	end

	#spawns a transfer that a client requests
	def find_peer_for_transfer(client,filename,chunk)
		peer=nil #the person to connect to
		clients.each do |c|
			if c.chunks_provided.provides?(filename,chunk)
				peer=c
				break
			end
		end
				
		peer=self if peer==this #peer=address of server
		
		return peer
	end	


#----------------------------------
#       Client file management
#----------------------------------

	def client_provides(client,filename,range)
		
	end

end
