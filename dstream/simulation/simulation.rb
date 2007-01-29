require File.dirname(__FILE__) + '/network_simulator'
require File.dirname(__FILE__) + '/../lib/server/server'
require File.dirname(__FILE__) + '/../lib/client/client'

class Simulation
  

  def run
    puts "Network simulator starting . . ."
    @sim=NetworkSimulator.new
    @server=Server.new @sim
    @clients=[]
    1.times do
      @clients.push( Client.new(@sim) )
    end

    @clients[0].connection.connect(@server)

    

  end

end
