require File.dirname(__FILE__) + "/../common/config.rb"

class ServerConfig < PDTPConfig
	attr_accessor :firewall

	def initialize
		super
		@firewall = false
	end

end
