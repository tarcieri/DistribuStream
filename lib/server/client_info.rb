#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

require File.dirname(__FILE__)+'/trust.rb'

module PDTP
  #stores information about a single connected client
  class ClientInfo
    attr_accessor :chunk_info, :trust
    attr_accessor :listen_port, :client_id
    attr_accessor :transfers
    
    def initialize
      @chunk_info=ChunkInfo.new
      @listen_port=6000 #default
      @trust=Trust.new
      @transfers=Hash.new
    end

    # returns true if this client wants the server to spawn a transfer for it
    def wants_download?
      transfer_state_allowed=5
      total_allowed=10
      transferring=0
      @transfers.each do |key, t|
        transferring=transferring+1 if t.verification_asked
        return false if transferring >= transfer_state_allowed
      end

      @transfers.size < total_allowed
    end 

    #this could have a different definition, but it works fine to use wants_download?
    alias_method :wants_upload?, :wants_download?
    
    #returns a list of all the stalled transfers this client is a part of
    def get_stalled_transfers
      stalled=[]
      timeout=20.0
      now=Time.now
      @transfers.each do |key,t|
        #only delete if we are the acceptor to prevent race conditions
        next if t.acceptor.user_data != self 
        if now-t.creation_time > timeout and not t.verification_asked
          stalled << t
        end
      end
      stalled
    end
  end

  #stores information about the chunks requested or provided by a client
  class ChunkInfo
    def initialize
      @files={}
    end

    #each chunk can either be provided, requested, transfer, or none
    def provide(filename,range); set(filename,range,:provided) ; end
    def unprovide(filename,range); set(filename,range, :none); end
    def request(filename,range); set(filename,range, :requested); end
    def unrequest(filename,range); set(filename,range, :none); end
    def transfer(filename,range); set(filename,range, :transfer); end

    def provided?(filename,chunk); get(filename,chunk) == :provided; end
    def requested?(filename,chunk); get(filename,chunk) == :requested; end

    #returns a high priority requested chunk
    def high_priority_chunk
      #right now return any chunk
      @files.each do |name,file|
        file.each_index do |i|
          return [name,i] if file[i]==:requested
        end
      end  
      
      nil
    end

    #calls a block for each chunk of the specified type
    def each_chunk_of_type(type)
      @files.each do |name,file|
        file.each_index do |i|
          yield(name,i) if file[i]==type
        end
      end 
    end

    class FileStats
      attr_accessor :file_chunks, :chunks_requested,:url
      attr_accessor :chunks_provided, :chunks_transferring
      
      def initialize
        @url=""
        @file_chunks=0
        @chunks_requested=0
        @chunks_provided=0
        @chunks_transferring=0
      end
    end

    #returns an array of FileStats objects for debug output
    def get_file_stats
      stats=[]
      @files.each do |name,file|
        fs=FileStats.new
        fs.file_chunks=file.size
        fs.url=name
        file.each do |chunk|
          fs.chunks_requested+=1 if chunk==:requested
          fs.chunks_provided+=1 if chunk==:provided
          fs.chunks_transferring+=1 if chunk==:transfer
        end
        stats << fs
      end
      
      stats 
    end

    #########
    protected
    #########

    def get(filename,chunk)
      @files[filename][chunk] rescue :neither
    end

    def set(filename,range,state)
      chunks=@files[filename]||=Array.new
      range.each { |i| chunks[i]=state }
    end
  end
end