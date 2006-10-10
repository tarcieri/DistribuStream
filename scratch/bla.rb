class Thinger
	def initialize
		str="string"
	end
	
	def printstr
		puts str
	end
end

puts "hello"

for i in 1..10
	print "i=#{i}\n"
end

10.times do
	print "i=kljasdf\n"  
end

thinger=Thinger.new("bla", "bla2")

require "yaml"
y thinger
#p thinger.a

