class Trust
  class Edge
    attr_accessor :trust, :success, :transfers

    def initialize(trust = 1, success = 1, transfers = 1)
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

  def success(node)
    if @outgoing[node].nil?
      @outgoing[node] = Edge.new
    else
      @outgoing[node].success += 1
      @outgoing[node].transfers += 1
    end
    normalize
  end

  def failure(node)
    @outgoing[node] = Edge.new if @outgoing[node].nil?
    @outgoing[node].transfers += 1
    normalize
  end

  def weight(node)
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
      print "link.success = ", link.success, "\n"
      print "link.transfers = ", link.transfers, "\n"
    end

    print "total_transfers=", total_transfers, "\n"

    @outgoing.each do |linkedge|
      link = linkedge[1]
      link.trust = (link.success / total_success) * (link.transfers / total_transfers)
      print "Trust: ", total_transfers, '/', total_transfers, "=",  link.trust, "\n"
    end

    @outgoing.each do |linkedge|
      target = linkedge[0]
      link = linkedge[1]

      [target.outgoing, target.implicit].each do |links|
        links.each do |nextlinkedge|
          nextlinktarget = nextlinkedge[0]
          nextlink = nextlinkedge[1]
          next unless outgoing[nextlinktarget].nil?

          if implicit[nextlinktarget].nil? || implicit[nextlinktarget].trust < (link.trust * nextlink.trust)
            implicit[nextlinktarget] = Edge.new(link.trust * nextlink.trust, nextlink.success, nextlink.transfers)
          end
        end
      end
    end
  end
end
