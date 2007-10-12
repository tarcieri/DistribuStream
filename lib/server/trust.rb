#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

#maintains trust information for a single client
class Trust
  class Edge
    attr_accessor :trust, :success, :transfers

    def initialize(trust = 1.0, success = 1.0, transfers = 1.0)
      @trust = trust
      @success = success
      @transfers = transfers
    end
  end

  attr_reader :outgoing, :implicit

  def initialize(incoming = {}, outgoing = {}, implicit = {})
    @incoming = incoming
    @outgoing = outgoing
    @implicit = implicit
  end

  #I have successfully downloaded a chunk from 'node'
  def success(node)
    if @outgoing[node].nil?
      @outgoing[node] = Edge.new
    else
      @outgoing[node].success += 1.0
      @outgoing[node].transfers += 1.0
    end
    normalize
  end

  #I have failed to download a chunk from 'node'
  def failure(node)
    @outgoing[node] = Edge.new if @outgoing[node].nil?
    @outgoing[node].transfers += 1.0
    normalize
  end

  #returns a number from 0 to 1 saying how much I trust 'node'
  def weight(node)
    return @outgoing[node].trust unless @outgoing[node].nil?
    return @implicit[node].trust unless @implicit[node].nil?
    0
  end

  # brings all trust values between 0 and 1
  def normalize
    total_success = 0
    total_transfers = 0

    @outgoing.each do |_, link|
      total_success += link.success
      total_transfers += link.transfers
    end

    @outgoing.each { |_, link| link.trust = link.success / total_transfers }
    @outgoing.each do |target, link|
      [target.outgoing, target.implicit].each do |links|
        links.each do |nextlinkedge|
          nextlinktarget = nextlinkedge[0]
          nextlink = nextlinkedge[1]
          next unless outgoing[nextlinktarget].nil?

          if implicit[nextlinktarget].nil? || implicit[nextlinktarget].trust < (link.trust * nextlink.trust)
            implicit[nextlinktarget] = Edge.new(
              link.trust * nextlink.trust, 
              nextlink.success, 
              nextlink.transfers
            )
          end
        end
      end
    end
  end
end
