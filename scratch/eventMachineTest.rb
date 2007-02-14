require 'rubygems'
 require 'eventmachine'

 module DumbHttpClient

   def post_init
     send_data "GET / HTTP/1.1\r\nHost: _\r\n\r\n"
     @data = ""
	  puts(get_peername)
	end

   def receive_data data
     @data << data
     if  @data =~ /[\n][\r]*[\n]/m
       puts "RECEIVED HTTP HEADER:"
       $`.each {|line| puts ">>> #{line}" }

       puts "Now we'll terminate the loop, which will also close the connection"
       EventMachine::stop_event_loop
     end
   end

   def unbind
     puts "A connection has terminated"
   end

 end # DumbHttpClient

 EventMachine::run {
   EventMachine::connect "www.google.com", 80, DumbHttpClient
 }
 puts "The event loop has ended"
