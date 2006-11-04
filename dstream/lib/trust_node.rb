require File.dirname(__FILE__) + '/trust_link'

class TrustNode
  def outgoing
    @outgoing
  end 
  
  def implicit
    @implicit
  end
  
  def initialize(incoming = {}, outgoing = {}, implicit = {})
    @incoming = incoming
    @outgoing = outgoing
    @implicit = implicit
  end
  
  def success(node)
    if @outgoing[node] == nil
      @outgoing[node] = TrustLink.new()
      normalize()
      return
    end
    
    @outgoing[node].success = @outgoing[node].success + 1
    @outgoing[node].transfers = @outgoing[node].transfers + 1
    normalize()
  end
  
  def failure(node)
    if @outgoing[node] == nil
      @outgoing[node] = TrustLink.new()
    end
    
    @outgoing[node].transfers = @outgoing[node].transfers + 1    
    normalize()
  end
  
  def trust(node)
    unless @outgoing[node] == nil
      return @outgoing[node].trust
    else
      unless @implicit[node] == nil
        return @implicit[node].trust
      else
        return 0
      end
    end
  end
  
  def normalize
    total_success = 0
    total_transfers = 0
    
    for linkedge in @outgoing
      link = linkedge[1]
      total_success += link.success
      total_transfers += link.transfers
    end
    
    puts "len:", @ongoing.size
    for linkedge in @outgoing
      link = linkedge[1]
      puts total_transfers, '/', total_transfers
      link.trust = (link.success / total_success) * (link.transfers / total_transfers)
    end
    
    for linkedge in @outgoing
      target = linkedge[0]          
      link = linkedge[1]
      
      for nextlinkedge in target.outgoing
        nextlinktarget = nextlinkedge[0]
        nextlink = nextlinkedge[1]
        if outgoing[nextlinktarget] == nil
          if implicit[nextlinktarget] == nil
            implicit[nextlinktarget] = TrustLink.new(link.trust * nextlink.trust, nextlink.success, nextlink.transfers)
          else
            if implicit[nextlinktarget].trust < (link.trust * nextlink.trust)
              implicit[nextlinktarget] = TrustLink.new(link.trust * nextlink.trust, nextlink.success, nextlink.transfers)
            end
          end
        end
      end
      
      for nextlinkedge in target.implicit
        nextlinktarget = nextlinkedge[0]
        nextlink = nextlinkedge[1]
        if outgoing[nextlinktarget] == nil
          if implicit[nextlinktarget] == nil
            implicit[nextlinktarget] = TrustLink.new(link.trust * nextlink.trust, nextlink.success, nextlink.transfers)
          else
            if implicit[nextlinktarget].trust < (link.trust * nextlink.trust)
              implicit[nextlinktarget] = TrustLink.new(link.trust * nextlink.trust, nextlink.success, nextlink.transfers)
            end
          end          
        end      
      end
    end
  end
  
end
