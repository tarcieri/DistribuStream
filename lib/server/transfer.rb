#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

module PDTP
  #stores information for the server about a specific transfer
  class Transfer
    attr_reader :taker, :giver, :url, :chunkid
    attr_reader :connector, :acceptor, :byte_range
    attr_accessor :transfer_id
    attr_accessor :creation_time
    attr_accessor :verification_asked

    def initialize(taker,giver,url,chunkid,byte_range,connector_receives=true)
      @taker,@giver,@url,@chunkid,@byte_range=taker,giver,url,chunkid,byte_range

      @verification_asked=false
      @creation_time=Time.now
      if !connector_receives then
        @connector=@giver
        @acceptor=@taker
      else
        @connector=@taker
        @acceptor=@giver
      end

      recompute_transfer_id
    end

    #calculates the transfer id for this transfer based on the local data
    def recompute_transfer_id
      id1=connector.user_data.client_id
      id2=acceptor.user_data.client_id
      @transfer_id=Transfer::gen_transfer_id(id1,id2,@url,@byte_range)
    end

    #generates a transfer id based on 2 client ids, a url, and a byte range
    def Transfer::gen_transfer_id(id1,id2,url,byte_range)
      a = id1<id2 ? id1 : id2
      b = id1<id2 ? id2 : id1
      return "#{a}$#{b}$#{url}$#{byte_range}"
    end

    def to_s
      return "taker=#{@taker}, giver=#{@giver}, connector=#{@connector}, acceptor=#{@acceptor}, url=#{@url}, chunk_id=#{@chunkid} range=#{@byte_range}"
    end

    def debug_str
      str=""
      str=str+"to_s=#{to_s}"
      str=str+"   taker_id=#{@taker.user_data.client_id} giver_id=#{@giver.user_data.client_id}" 
      return str
    end
  end
end