require "stringio"

class MarshalBuffer
	def appendString(str)
		@buffer||=String.new
		@buffer=@buffer+str	
	end

	def readObject
		@buffer||=String.new
		io=StringIO.new(@buffer)
		obj=Marshal.load(io) rescue nil
		@buffer=@buffer[io.tell,@buffer.length-1] if obj
		return obj	
	end
end

def testMarshalBuffer
	obj1=[1,2,3,"hi"]
	obj2={1=>4,3=>10}
	str1=Marshal.dump(obj1)
	str2=Marshal.dump(obj2)
	
	str1first=str1[0,4]
	str1last=str1[4,str1.length-1]
	
	puts "obj1="+obj1.inspect,"obj2="+obj2.inspect
	puts "obj1 marshal="+str1.inspect, "obj2 marshal="+str2.inspect
	puts "obj1 first half="+str1first.inspect
	puts "obj1 second half="+str1last.inspect
	
	
	buf=MarshalBuffer.new
	print "Read from empty buffer:",buf.readObject,"\n"
	buf.appendString(str1first)
	print "Read from half full buffer:",buf.readObject,"\n"
	buf.appendString(str1last)
	print "Read from full buffer:",buf.readObject.inspect,"\n"
	
	buf.appendString(str1)
	buf.appendString(str2)
	print "Read from double full buffer:",buf.readObject.inspect,"\n"
	print "Read from full buffer:",buf.readObject.inspect,"\n"
	print "Read from empty buffer:",buf.readObject,"\n"
	
end

testMarshalBuffer


