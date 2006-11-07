require File.dirname(__FILE__) + '/trust_link'

class TrustNode
  attr_reader :outgoing, :implicit
 
  def initialize(incoming = {}, outgoing = {}, implicit = {})
    @incoming = incoming
    @outgoing = outgoing
    @implicit = implicit
  end
  
  def success(node)
    @outgoing[node] = TrustLink.new; normalize if @outgoing[node].nil?
    @outgoing[node].success += 1
    @outgoing[node].transfers += 1
    normalize
  end
  
  def failure(node)
    @outgoing[node] = TrustLink.new if @outgoing[node].nil?
    @outgoing[node].transfers += 1    
    normalize
  end
  
  def trust(node)
    return @outgoing[node].trust unless @outgoing[node].nil?
    return @implicit[node].trust unless @implicit[node].nil?
    0
  end
  
  def normalize
    total_success = 0
    total_transfers = 0
  
    @outgoing.each do |linkedge|
      link = linkedge[1]
      total_success += link.success
      total_transfers += link.transfers
    end
    
    puts "len:", @ongoing.size
    @outgoing.each do |linkedge|
      link = linkedge[1]
      puts total_transfers, '/', total_transfers
      link.trust = (link.success / total_success) * (link.transfers / total_transfers)
    end
    
    @outgoing.each do |linkedge|
      target = linkedge[0]          
      link = linkedge[1]
      
      target.outgoing.each do |nextlinkedge|
        nextlinktarget = nextlinkedge[0]
        nextlink = nextlinkedge[1]
        next unless outgoing[nextlinktarget].nil?
        
        if implicit[nextlinktarget].nil?
          implicit[nextlinktarget] = TrustLink.new(link.trust * nextlink.trust, nextlink.success, nextlink.transfers)
        elsif implicit[nextlinktarget].trust < (link.trust * nextlink.trust)
            implicit[nextlinktarget] = TrustLink.new(link.trust * nextlink.trust, nextlink.success, nextlink.transfers)
        end
      end
      
      target.implicit.each do |nextlinkedge|
        nextlinktarget = nextlinkedge[0]
        nextlink = nextlinkedge[1]
        next unless outgoing[nextlinktarget].nil?
        
        if implicit[nextlinktarget].nil?
          implicit[nextlinktarget] = TrustLink.new(link.trust * nextlink.trust, nextlink.success, nextlink.transfers)
        elsif implicit[nextlinktarget].trust < (link.trust * nextlink.trust)
          implicit[nextlinktarget] = TrustLink.new(link.trust * nextlink.trust, nextlink.success, nextlink.transfers)
        end          
      end
    end
  end
end
