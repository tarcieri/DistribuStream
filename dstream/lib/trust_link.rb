class TrustLink
  def trust
    @trust
  end
  
  def trust=(newtrust)
    @trust = newtrust
  end
  
  def success
    @success
  end
  
  def success=(newsuccess)
    @success = newsuccess
  end
  
  def transfers
    @transfers
  end
  
  def transfers=(newtransfers)
    @transfers = newtransfers
  end
  
  def initialize(trust = 1, success = 1, transfers = 1)
    @trust = trust
    @success = success
    @transfers = transfers
  end
end
