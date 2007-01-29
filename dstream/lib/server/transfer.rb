$: << File.dirname(__FILE__) + '/../common'
require 'server_chunk_transfer_sm'

class Transfer
  attr_reader :fsm
  attr_accessor :peer1
  attr_accessor :peer2
  attr_accessor :filename
  attr_accessor :chunk
  attr_accessor :status

  def initialize
    @fsm = Transfer_sm.new(self)
  end
 
  def connect()
  end

  def transfer()
  end

  def map()
  end

  def execute_transition(message)
    @fsm.method(message).call
  end  
end
