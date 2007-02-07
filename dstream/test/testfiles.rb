require File.dirname(__FILE__)+'/../lib/server/server_file_service.rb'
require File.dirname(__FILE__)+'/../lib/client/client_file_service.rb'

sfs=ServerFileService.new
sfs.root=File.dirname(__FILE__)+'/../../testfiles'
url="pdtp://bla.com/test.txt"
puts sfs.get_info(url).inspect
puts sfs.get_chunk_data(url,0).inspect

cfs=ClientFileService.new
puts cfs.get_info(url).inspect
puts cfs.get_chunk_data(url,0).inspect
cfs.set_info(url,sfs.get_info(url))
cfs.set_chunk_data(url,0,sfs.get_chunk_data(url,0))

puts cfs.get_info(url).inspect
puts cfs.get_chunk_data(url,0).inspect
