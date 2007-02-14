require File.dirname(__FILE__)+'/../common/config'

class ClientConfig < PDTPConfig
	attr_accessor :url,:listen_port,:provide
	
	def initialize
		super
		@url = 'pdtp://bla.com/test2.txt'
		@listen_port = 8000
		@provide = false
	end

end
