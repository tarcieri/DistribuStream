require 'line_separator'

context "A line separator with no cached data, when \#extract is invoked" do
  setup do
    @ls = LineSeparator.new
    @yielded = []
    @reverse = lambda {|x| @yielded << x; x.reverse}
  end

  specify "should yield a line if the line is newline-terminated and return an array with the result of the block" do
    @ls.extract("asdf\n", &@reverse).should == ['fdsa']
    @yielded.should == ['asdf']
  end

  specify "should yield two lines with two nl-terminated lines and return array with return results" do
    @ls.extract("asdf\njkl\n", &@reverse).should == ['fdsa', 'lkj']
    @yielded.should == ['asdf', 'jkl']
  end

  specify "should return empty array and yield nothing with non-terminated extract" do
    @ls.extract("asdf", &@reverse).should == []
    @yielded.should_be_empty
  end

  specify "should return the first half of a string with a newline in the middle" do
    @ls.extract("asdf\njkl", &@reverse).should == ['fdsa']
    @yielded.should == ['asdf']
  end

  specify "should handle all kinds of stuff! whee!" do
    @ls.extract("asdf\njkl", &@reverse).should == ['fdsa']
    @ls.extract("\nqwer\nty\n", &@reverse).should == ['lkj', 'rewq', 'yt']
    @ls.extract("\nasdf\njkl", &@reverse).should == ['','fdsa']
    @ls.extract("what\n", &@reverse).should == ['tahwlkj']
    @yielded.should == ['asdf', 'jkl', 'qwer', 'ty', '', 'asdf', 'jklwhat']
  end

end

context "A line separator with a non-terminated line already extract, when \#extract is invoked" do
  setup do
    @ls = LineSeparator.new
    @yielded = []
    @reverse = lambda {|x| @yielded << x; x.reverse}
    @ls.extract("asdf", &@reverse).should == []
    @yielded.should_be_empty
  end

  specify "should return empty array and yield nothing with non-terminated extract" do
    @ls.extract("asdf", &@reverse).should == []
    @yielded.should_be_empty
  end

  specify "should yield full combined line with terminated string" do
    @ls.extract("jkl\n", &@reverse).should == ['lkjfdsa']
    @yielded.should == ['asdfjkl']
  end

  specify "should yield combined first half of a string with a newline in the middle" do
    @ls.extract("asdf\njkl", &@reverse).should == ['fdsafdsa']
    @yielded.should == ['asdfasdf']
  end

  specify "should yield cached line with a newline" do
    @ls.extract("\n", &@reverse).should == ['fdsa']
    @yielded.should == ['asdf']
  end

  specify "should yield two lines when followed by newline+second line+newline" do
    @ls.extract("\njkl\n", &@reverse).should == ['fdsa','lkj']
    @yielded.should == ['asdf', 'jkl']
  end

end
