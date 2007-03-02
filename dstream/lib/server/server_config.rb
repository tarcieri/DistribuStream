require File.dirname(__FILE__) + "/../common/config.rb"

class ServerConfig < PDTPConfig
	attr_accessor :firewall,:chunk_size

	def initialize
		super
		@firewall = false
		@chunk_size = 512
	end

end
