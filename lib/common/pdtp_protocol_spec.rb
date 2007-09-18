require File.dirname(__FILE__)+"/pdtp_protocol.rb"

context "PDTPProtocol obj_matches_type? " do


  specify "type :url works" do
    PDTPProtocol::obj_matches_type?("http://bla.com/test3.mp3",:url).should == true
    PDTPProtocol::obj_matches_type?(4,:url).should == false
  end

  specify "type :range works" do
    PDTPProtocol::obj_matches_type?(0..4,:range).should == true
    PDTPProtocol::obj_matches_type?(4,:range).should == false
    PDTPProtocol::obj_matches_type?( {"min"=>0,"max"=>4} , :range ).should == true
  end

  specify "type :ip works" do
    PDTPProtocol::obj_matches_type?("127.0.0.1", :ip).should == true
    PDTPProtocol::obj_matches_type?("127.0.0.1.1", :ip).should == false
  end

  specify "type :int works" do
    PDTPProtocol::obj_matches_type?(4,:int).should == true
    PDTPProtocol::obj_matches_type?("hi",:int).should == false
  end

  specify "type :bool works" do
    PDTPProtocol::obj_matches_type?(true, :bool).should == true
    PDTPProtocol::obj_matches_type?(0,:bool).should == false
  end

  specify "type :string works" do
    PDTPProtocol::obj_matches_type?("hi", :string).should == true
    PDTPProtocol::obj_matches_type?(6, :string).should == false
  end

end

context "PDTPProtocol validate_message" do
  specify "optional params work" do
    msg1={"type"=>"request", "url"=>"pdtp://bla.com/test.txt", "range"=>0..4}
    msg2={"type"=>"request", "url"=>"pdtp://bla.com/test.txt" }
    msg3={"type"=>"request", "range"=> "hi", "url"=>"pdtp://bla.com/test.txt" }

    lambda{ PDTPProtocol::validate_message(msg1)}.should_not raise_error
    lambda{ PDTPProtocol::validate_message(msg2)}.should_not raise_error
    lambda{ PDTPProtocol::validate_message(msg3)}.should raise_error
  end

  specify "required params work" do
    msg1={"type"=>"ask_info"}
    msg2={"type"=>"ask_info", "url"=>"pdtp://bla.com/test.txt"}
    msg3={"type"=>"ask_info", "url"=>42 }

    lambda{ PDTPProtocol::validate_message(msg1)}.should raise_error
    lambda{ PDTPProtocol::validate_message(msg2)}.should_not raise_error
    lambda{ PDTPProtocol::validate_message(msg3)}.should raise_error
  end

end
