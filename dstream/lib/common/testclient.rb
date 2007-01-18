require "network_manager"

client=NetworkManager.new
client.connect("127.0.0.1",8000)
client.run