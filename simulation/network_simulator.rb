
# Address= [simulator,port]
# Queue item = [connection,message]

#this class implements the NetworkManager interface well enough for it to be used in testing
class NetworkManagerSim

  class Connection
    #public interface
    
    def send_message(message)
      remote[0].incoming_message(self,message)
    end 
    
    def local_address; local[0].to_s; end
    def local_port; local[1]; end   
    def remote_address; remote[0].to_s; end
    def remote_port; remote[1]; end
    
    #private, don't use outside of this module

    attr_accessor :local,:remote #local and remote [simulator,port]


    

  end

  attr_accessor :connections,:listeners #needed so we can access another NetworkManagerSim's connections
  #protected :connections,:listeners

  @@message_queue=Array.new

  def initialize
    @listeners=Array.new
    @connections=Array.new
    @unique_source_port=5000
  end

  def connect(address,port)
    @unique_source_port=@unique_source_port+1

    con=Connection.new
    con.local=[self,@unique_source_port]
    con.remote=[address,port]
    @connections<<con

    #open a connection back from the remote host
    con2=Connection.new
    con2.local=con.remote
    con2.remote=con.local
    address.connections<<con
    
    return con
  end

  #source connection is the connection that sent this message from the other side
  def incoming_message(source_connection,message)
    #puts "source_connection=#{source_connection.inspect}"
    #puts "@connections=#{@connections.inspect}"
    #cons=@connections.select {|c| c.local==source_connection.remote && c.remote==source_connection.local }
    #connection=cons[0] rescue nil
    connection=@connections[0]
    @@message_queue<<[connection,message] 	
  end

  def register_message_listener(listener)
    @listeners<<listener
  end

  def NetworkManagerSim.run

    while @@message_queue.size>0 do
      #puts "mq=#{@@message_queue.inspect}"
      message=@@message_queue.pop
      
      net_sim=message[0].local[0]
      net_sim.listeners.each { |listener| listener.dispatch_message(message[1],message[0]) }  
    end 

  end

end

class BasicMessageHandler 
  def dispatch_message(message,connection)
    puts "dispatching message: #{message.inspect} from remote: #{connection.remote_address},#{connection.remote_port}"
    connection.send_message("Yo wassup?")
  end
end

c1net=NetworkManagerSim.new
c2net=NetworkManagerSim.new

c1=BasicMessageHandler.new
c2=BasicMessageHandler.new

c1net.register_message_listener(c1)
c2net.register_message_listener(c2)


connection=c1net.connect(c2net,5000)
connection.send_message("This is a message.")
NetworkManagerSim.run



