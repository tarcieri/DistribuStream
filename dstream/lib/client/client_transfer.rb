require File.dirname(__FILE__)+'/client_file_service'

class ClientTransfer
  attr_reader :peer, :url, :chunkid, :transfer_direction, :finished
  attr_accessor :go_ahead # if this is true, we are free to send/receive data


  #peer is a connection to the appropriate peer
  #transfer direction is either :in or :out
  def initialize(peer, url, chunkid, transfer_direction, file_service)
    @peer, @url, @chunkid = peer, url, chunkid    
    @transfer_direction = transfer_direction
    @go_ahead = false
    @finished = false
    @file_service = file_service

    @bytes_transferred = 0
    @chunk_size = file_service.get_chunk_size(@url, @chunkid)
  end

  def send_initial_request
    message = {
      "type" => transfer_direction==:out ? "take" : "give",
      "url" => @url,
      "chunk_id" => @chunkid
    }
    @peer.send_message(message) 
  end  

  #called periodically to send pending data
  def update
    @@log.debug "go_ahead=#{@go_ahead} finished=#{@finished}"
    return if @go_ahead == false or @finished == true or @transfer_direction == :in
    
    data = @file_service.get_chunk_data(@url,@chunkid)
    message = {
      "type" => "data",
      "data" => data
    }
    peer.send_message(message)
    
    message = { 
      "type" => "completed",
      "url" => @url,
      "chunk_id" => @chunkid
    }
    #FIXME send this to the server
    
    @finished = true
    
  end  

	def to_s
	  return "peer=#{@peer}, url=#{@url}, chunk_id=#{@chunkid}, transfer direction=#{@transfer_direction}, finished=#{@finished}, go ahead=#{@go_ahead}"
	end

end
