
class Thinger
	def initialize(_str)
		@str=_str
	end
	
	def printstr
		puts @str
		puts "This is a thinger"
	end
end

puts "Client starting"

require "socket"
port=8000


newsock=TCPSocket.new("localhost",port) rescue nil 
puts "it broke" unless newsock



printf("client connected\n");



while true
	input=gets.chomp
	
	thing=Thinger.new(input)
	thing.printstr
	Marshal.dump(thing,newsock)
	 

	#data=Marshal.dump(input)
	#print "string=" 
	#input.each_byte {|c| print c, ' ' }
	#print "marshalled="
	#data.each_byte {|c| print c, ' ' }
	
	#Marshal.dump(input,newsock)
end
