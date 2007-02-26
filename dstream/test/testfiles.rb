require File.dirname(__FILE__)+'/../lib/server/server_file_service.rb'
require File.dirname(__FILE__)+'/../lib/client/client_file_service.rb'
require File.dirname(__FILE__)+'/../lib/client/client.rb'
require File.dirname(__FILE__)+'/../lib/common/pdtp_protocol.rb'
require File.dirname(__FILE__)+'/../lib/client/memory_buffer.rb'

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
puts sfs.get_info(url).read(0..10)

puts sfs.get_info("pdtp://bla.com/kljsaefklj").inspect

test_range_to_hash( { "type"=>"provide", "range"=>0..-1} )
test_range_to_hash( { "type"=>"provide", "range"=>0..100} )
test_range_to_hash( { "type"=>"provide", "range"=>50..-1} )
puts

test_hash_to_range( {"type"=>"provide"} )
test_hash_to_range( {"type"=>"provide", "range"=>{"max"=>100} } )
test_hash_to_range( {"type"=>"request", "range"=>{"min"=>20} } )

mb=MemoryBuffer.new
e1=MemoryBuffer::Entry.new(10,"hello")
e2=MemoryBuffer::Entry.new(0,"bla12345678")
e3=MemoryBuffer::Entry.new(0,"bla1234567")

puts "e1= #{e1.start_pos} #{e1.end_pos}"
puts "e2= #{e2.start_pos} #{e2.end_pos}"
puts mb.intersects?(e1,e2)
puts mb.intersects?(e2,e1)
puts mb.intersects?(e1,e3)
puts mb.intersects?(e3,e1)

puts "testing memory buffer"
mb.write(10,"hello")
puts mb.read(0..10).inspect # false
puts mb.read(10..11).inspect # "he"
puts mb.read(14..100).inspect #false
mb.write(16,"goodbye")
puts mb.read(10..14).inspect # "hello"
puts mb.read(11..22).inspect # false
mb.write(15,"&")
puts mb.read(11..22).inspect # "ello&goodbye"

mb.write(14,"!!!")
puts mb.read(11..22).inspect # "ell!!!oodbye"

