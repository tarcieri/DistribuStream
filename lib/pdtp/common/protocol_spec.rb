#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

require File.dirname(__FILE__) + '/protocol'

describe "PDTP::Protocol obj_matches_type? " do
  it "type :url works" do
    PDTP::Protocol.obj_matches_type?("http://bla.com/test3.mp3",:url).should == true
    PDTP::Protocol.obj_matches_type?(4,:url).should == false
  end

  it "type :range works" do
    PDTP::Protocol.obj_matches_type?(0..4,:range).should == true
    PDTP::Protocol.obj_matches_type?(4,:range).should == false
    PDTP::Protocol.obj_matches_type?( {"min"=>0,"max"=>4} , :range ).should == true
  end

  it "type :ip works" do
    PDTP::Protocol.obj_matches_type?("127.0.0.1", :ip).should == true
    PDTP::Protocol.obj_matches_type?("127.0.0.1.1", :ip).should == false
  end

  it "type :int works" do
    PDTP::Protocol.obj_matches_type?(4,:int).should == true
    PDTP::Protocol.obj_matches_type?("hi",:int).should == false
  end

  it "type :bool works" do
    PDTP::Protocol.obj_matches_type?(true, :bool).should == true
    PDTP::Protocol.obj_matches_type?(0,:bool).should == false
  end

  it "type :string works" do
    PDTP::Protocol.obj_matches_type?("hi", :string).should == true
    PDTP::Protocol.obj_matches_type?(6, :string).should == false
  end

end

describe "PDTP::Protocol validate_message" do
  it "optional params work" do
    msg1 = {"type"=>"request", "url"=>"pdtp://bla.com/test.txt", "range"=>0..4}
    msg2 = {"type"=>"request", "url"=>"pdtp://bla.com/test.txt" }
    msg3 = {"type"=>"request", "range"=> "hi", "url"=>"pdtp://bla.com/test.txt" }

    proc { PDTP::Protocol.validate_message(msg1)}.should_not raise_error
    proc { PDTP::Protocol.validate_message(msg2)}.should_not raise_error
    proc { PDTP::Protocol.validate_message(msg3)}.should raise_error
  end

  it "required params work" do
    msg1 = {"type"=>"ask_info"}
    msg2 = {"type"=>"ask_info", "url"=>"pdtp://bla.com/test.txt"}
    msg3 = {"type"=>"ask_info", "url"=>42 }

    proc { PDTP::Protocol.validate_message(msg1)}.should raise_error
    proc { PDTP::Protocol.validate_message(msg2)}.should_not raise_error
    proc { PDTP::Protocol.validate_message(msg3)}.should raise_error
  end

end
