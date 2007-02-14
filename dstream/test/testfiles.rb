require File.dirname(__FILE__)+'/../lib/server/server_file_service.rb'
require File.dirname(__FILE__)+'/../lib/client/client_file_service.rb'
require File.dirname(__FILE__)+'/../lib/client/client.rb'

sfs=ServerFileService.new
sfs.root=File.dirname(__FILE__)+'/../../testfiles'
url="pdtp://bla.com/test2.txt"
puts sfs.get_info(url).inspect
puts sfs.get_info(url).chunk_data(0,0..511)

puts sfs.get_info("pdtp://bla.com/kljsaefklj").inspect
