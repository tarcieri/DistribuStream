require 'rubygems'
require 'eventmachine'
require "yaml"

class Thinger
	def initialize(_str)
		@str=_str
	end

	def printstr
		puts @str
		puts "This is a thinger"
	end
end


module EchoServer

	def receive_data data
		#puts "got something:#{data.inspect}"
		#data.each_byte { |b| print b," " }
	
		obj=Marshal.load(data)
		obj.printstr
		
		#send_data ">>>you sent: #{data}"
		#close_connection if data =~ /quit/i

	end

end

EventMachine::run do
	EventMachine::start_server "127.0.0.1", 8081, EchoServer
end
