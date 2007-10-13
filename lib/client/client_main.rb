#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

require 'optparse'
require 'rubygems'
require 'eventmachine'
require 'mongrel'

require File.dirname(__FILE__) + '/client'
require File.dirname(__FILE__) + '/client_file_service'
require File.dirname(__FILE__) + '/../server/server_file_service'
require File.dirname(__FILE__) + '/../common/common_init'

common_init("dstream_client")

# Fine all suitable files in the give path
def find_files(base_path)
  require 'find'

  found = []
  excludes = %w{".svn CVS}
  base_full = File.expand_path(base_path)

  Find.find(base_full) do |path|
    if FileTest.directory?(path)
      if excludes.include?(File.basename(path)) then
        Find.prune
      else
        next
      end
    else
      filename = path[(base_path.size - path.size + 1)..-1] #the entire file path after the base_path
      found << filename
    end
  end

  return found
end

# Implements the file service for the pdtp protocol
class FileServiceProtocol < PDTP::Protocol
  def initialize *args
    super
  end

  # Called after a connection to the server has been established
  def connection_completed
    begin
      listen_port = @@config[:listen_port]

      #create the client
      client = PDTP::Client.new
      PDTP::Protocol.listener = client
      client.server_connection = self
      client.generate_client_id listen_port

      # Start a mongrel server on the specified port.  If it isnt available, keep trying higher ports
      begin
        mongrel_server=Mongrel::HttpServer.new '0.0.0.0', listen_port
      rescue Exception=>e
        listen_port+=1
        retry
      end

      @@log.info "listening on port #{listen_port}"
      mongrel_server.register "/", client
      mongrel_server.run

      # Tell the server a little bit about ourself
      request={
        "type"=>"client_info",
        "listen_port"=>listen_port,
        "client_id"=>client.my_id
      }
      send_message request

      @@log.info 'This client is providing"'
      sfs = PDTP::ServerFileService.new
      sfs.root = @@config[:file_root]
      client.file_service = sfs #give this client access to all data

      hostname = @@config[:provide_hostname]

      # Provide all the files in the root directory
      files = find_files(@@config[:file_root] )
      files.each do |file|
        request={
          "type"=>"provide",
          "url"=>"http://#{hostname}/#{file}"
        }
        send_message request
      end
    rescue Exception => e
      puts "Exception in connection_completed: #{e}"
      puts e.backtrace.join("\n")
      exit
    end
  end  

  def unbind
    super
    puts "Disconnected from PDTP server."
  end
end

# Run the EventMachine reactor loop
EventMachine::run do
  host,port,listen_port = @@config[:host],@@config[:port],@@config[:listen_port]
  connection=EventMachine::connect host,port,FileServiceProtocol
  @@log.info("connecting with ev=#{EventMachine::VERSION}")
  @@log.info("host= #{host}  port=#{port}")
end