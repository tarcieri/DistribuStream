require File.dirname(__FILE__)+'/../lib/server/server_file_service.rb'
require File.dirname(__FILE__)+'/../lib/client/client_file_service.rb'
require File.dirname(__FILE__)+'/../lib/client/client.rb'
require File.dirname(__FILE__)+'/../lib/common/pdtp_protocol.rb'

def test_range_to_hash(hash)
  puts "before:"+hash.inspect
  PDTPProtocol.new(4).range_to_hash(hash)
  puts "after:"+hash.inspect
end

def test_hash_to_range(hash)
  puts "before:"+hash.inspect
  PDTPProtocol.new(4).hash_to_range(hash)
  puts "after:"+hash.inspect
end



sfs=ServerFileService.new
sfs.root=File.dirname(__FILE__)+'/../../testfiles'
url="pdtp://bla.com/test2.txt"
puts sfs.get_info(url).inspect
puts sfs.get_info(url).chunk_data(0,0..511)

puts sfs.get_info("pdtp://bla.com/kljsaefklj").inspect

test_range_to_hash( { "type"=>"provide", "range"=>0..-1} )
test_range_to_hash( { "type"=>"provide", "range"=>0..100} )
test_range_to_hash( { "type"=>"provide", "range"=>50..-1} )
puts

test_hash_to_range( {"type"=>"provide"} )
test_hash_to_range( {"type"=>"provide", "range"=>{"max"=>100} } )
test_hash_to_range( {"type"=>"request", "range"=>{"min"=>20} } )

