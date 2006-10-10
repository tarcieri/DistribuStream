require "socket"

port=8000

newsock=TCPSocket.new("localhost",port)
printf("client connected\n");


startTime=Time.now.to_i

printf("startime=%d\n",startTime)
numBytes=0

while !newsock.eof? do
	#printf("sending\n")
	numBytes=numBytes+newsock.readpartial(2000).length
end	

printf("recved=%d\n",numBytes)

endTime=Time.now.to_i

diff=endTime-startTime
printf("endTime=%d  diff=%d\n",endTime,diff)

printf("speed=%f\n",numBytes.to_f/(1024.0*1024.0)/diff.to_f)

