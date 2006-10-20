require 'filemanager'
require 'netinterfacehandler'

class Server < NetInterfaceHandler
	attr_accessor :file_manager
	
	def dispatch(address,packet)		
		handlers={ 
			:askinfo=> :dispatch_askinfo,
			:transfer_status => :dispatch_transfer_status,
			:request=>:dispatch_request
		}

		handler=handlers[ packet[:type] ]
		raise "Invalid packet" if handler==nil
		
		method(handler).call(address,packet)
		
	end
	
	def dispatch_askinfo(address,packet)
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
		
		send(address,ret)
	end	

end