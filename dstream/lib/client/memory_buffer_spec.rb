require File.dirname(__FILE__)+"/memory_buffer.rb"

context "A new memory buffer" do
  setup do
    @mb=MemoryBuffer.new
  end

  specify "has 0 bytes stored, read fails" do
    @mb.bytes_stored.should == 0
    @mb.read(0..1).should == nil
  end  
end

context "A memory buffer with one entry" do
  setup do
    @mb=MemoryBuffer.new
    @mb.write(0,"hello")
  end

  specify "bytes_stored works" do
    @mb.bytes_stored.should == 5
  end

  specify "read works" do
    @mb.read(0..4).should == "hello"
    @mb.read(1..1).should == "e"
    @mb.read(-1..2).should == nil
    @mb.read(0..5).should == nil
  end
end

context "A memory buffer with two overlapping entries" do
  setup do
    @mb=MemoryBuffer.new
    @mb.write(3,"hello")
    @mb.write(7,"World")
  end
  
  specify "bytes_stored works" do
    @mb.bytes_stored.should == 9
  end

  specify "read works" do
    @mb.read(3..12).should == nil
    @mb.read(3..11).should == "hellWorld"
    @mb.read(3..1).should == nil
    @mb.read(2..4).should == nil
  end

end

context "A memory buffer with three overlapping entries" do
  setup do
    @mb=MemoryBuffer.new
    @mb.write(3,"hello")
    @mb.write(7,"World")
    @mb.write(2,"123456789ABCDEF")
  end

  specify "bytes_stored works" do
    @mb.bytes_stored.should == 15
  end

  specify "read works" do
    @mb.read(2..16).should == "123456789ABCDEF"
    @mb.read(2..17).should == nil
  end
end

context "A memory buffer with two touching entries" do
  setup do
    @mb=MemoryBuffer.new
    @mb.write(3,"hello")
    @mb.write(8,"World")
  end

  specify "bytes_stored works" do
    @mb.bytes_stored.should == 10
  end
  
  specify "read works" do
    @mb.read(3..12).should == "helloWorld"
  end
end

context "A memory buffer with a chain of overlapping entries" do
  setup do
    @mb=MemoryBuffer.new
    @mb.write(3,"a123")
    @mb.write(4,"b4")
    @mb.write(0,"012c")
  
    #___a123
    #___ab43
    #012cb43

  end

  specify "bytes_stored works" do
    @mb.bytes_stored.should == 7
  end

  specify "read works" do
    @mb.read(0..6).should == "012cb43"
    @mb.read(3..6).should == "cb43"
  end
end
