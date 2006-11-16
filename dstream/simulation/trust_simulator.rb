#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/server/trust'

class TrustSimulator
  class SimTrust < Trust
    attr_accessor :edges
  
    def initialize(edges = {})
      super
        @edges = edges
    end
  end

  def initialize(num_nodes = 5, overall_reliability = 1.0, variance = 0.1)
    @nodes = [];

    num_nodes.times do |i|
      @nodes[i] = SimTrust.new
    end

    @nodes.each do |node|
      @nodes.each do |other|
        if node != other
          r = overall_reliability + ((rand - 0.5) * variance)
          if r <= 1.0
            node.edges[other] = r
          else
            node.edges[other] = 1.0
          end
        end
      end
    end
  end

  def run(num_transfers = 1000)
    num_transfers.times do |t|
      n1 = nil
      n2 = nil
      while n1 == n2 do
        n1 = @nodes[@nodes.size * rand]
        n2 = @nodes[@nodes.size * rand]
      end

      if rand < n1.edges[n2]
        n1.success(n2)
      else
        n1.failure(n2)
      end
    end

    k_total = 0.0
    num_samples = 1.0
    k_vals = []
    @nodes.each do |node|
      @nodes.each do |other|
        if node != other
          k = node.weight(other) / node.edges[other]
          print "k=", k, "\n"
          k_total += k
          num_samples += 1

          k_vals << k
        end
      end
    end

    coverage = num_samples / ((@nodes.size) * (@nodes.size))
    k_avg = k_total / num_samples

    k_variance = 0.0
    k_vals.each do |k|
      k_variance += (k - k_avg) * (k - k_avg)
    end
    k_variance = (1.0 / num_samples) * k_variance

    print "num_samples = ", num_samples, "\n"
    print "num_transfers = ", num_transfers, "\n"
    print "coverage = ", coverage, "\n"
    print "k_avg = ", k_avg, "\n"
    print "k_variance = ", k_variance, "\n"
    k_variance
  end
end

sim = TrustSimulator.new(num_nodes = 20, overall_reliability = 0.4, variance = 0.5)
sim.run(10000)