#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

require 'rubygems'
require 'eventmachine'
require 'mongrel'
require 'optparse'

require File.dirname(__FILE__) + '/client'
require File.dirname(__FILE__) + '/client_file_service'
require File.dirname(__FILE__) + '/../common/common_init'

common_init("dstream_client")

# Implementation of a ruby test client for the pdtp protocol
class TestClientProtocol < PDTP::Protocol
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
      client.file_service = PDTP::Client::FileService.new

      # Start a mongrel server on the specified port.  If it isnt available, keep trying higher ports
      begin
        mongrel_server = Mongrel::HttpServer.new('0.0.0.0', listen_port)
      rescue Exception => e
        listen_port += 1
        retry
      end

      @@log.info "listening on port #{listen_port}"
      mongrel_server.register '/', client
      mongrel_server.run

      # Tell the server about ourself
      send_message :client_info, :listen_port => listen_port, :client_id => client.my_id

      # Ask the server for some information on the file we want
      send_message :ask_info, :url => @@config[:request_url]      

      # Request the file
      send_message :request, :url => @@config[:request_url]

      @@log.info "This client is requesting"
    rescue Exception=>e
      puts "Exception in connection_completed: #{e}"
      puts e.backtrace.join("\n")
      exit
    end
  end  

  def unbind
    super
    puts 'Disconnected from PDTP server.'
  end
end

# Run the EventMachine reactor loop
EventMachine::run do
  host, port, listen_port = @@config[:host], @@config[:port], @@config[:listen_port]
  connection = EventMachine::connect host, port, TestClientProtocol
  @@log.info "connecting with ev=#{EventMachine::VERSION}"
  @@log.info "host= #{host}  port=#{port}"
end