require "socket"

port=8000

serverSocket=TCPServer.new("",port)
serverSocket.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR,1)
printf("server started on port %d\n",port);

newsock=serverSocket.accept
name=sprintf("[%s|%s]",newsock.peeraddr[2],newsock.peeraddr[1])
printf("got connection from %s\n",name)


data="Hello world omg wtf bbq!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
data=data+data+data+data+data+data+data+data+data+data+data+data+data

printf("data size=%d\n",data.length)

sent=0

100000.times do
	#printf("sending\n")
	sent=sent+newsock.write(data)
end	


newsock.close

printf("sent=%d\n",sent)


printf(data)
		
	