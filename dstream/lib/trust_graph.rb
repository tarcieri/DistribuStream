require File.dirname(__FILE__) + '/trust_link'
require File.dirname(__FILE__) + '/trust_node'

a = TrustNode.new()
b = TrustNode.new()
c = TrustNode.new()

puts a.inspect
puts b.inspect
puts c.inspect

b.success(c)
a.success(c)
a.failure(c)


puts a.inspect
puts b.inspect
puts c.inspect