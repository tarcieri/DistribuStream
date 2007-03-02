require File.dirname(__FILE__)+'/../common/config'

class ClientConfig < PDTPConfig
	attr_accessor :url,:listen_port,:provide,:byte_start,:byte_end
	
	def initialize
		super
		@url = 'pdtp://bla.com/test2.txt'
		@listen_port = 8000
		@provide = false
		@byte_start = 0
		@byte_end = -1
	end

end
