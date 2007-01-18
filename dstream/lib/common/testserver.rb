
require File.dirname(__FILE__) + '/../server/server_file_service'
require "network_manager"

bla=ServerFileService.new
bla.root="../../test"
p bla.get_info("pdtp://server.com/stuff.txt")

server=NetworkManager.new
server.listen(8000)
server.run