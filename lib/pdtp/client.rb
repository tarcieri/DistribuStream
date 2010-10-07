#--
# Copyright (C) 2006-08 Medioh, Inc. (info@medioh.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.org/
#++

require 'revactor'
require 'digest/md5'

=begin
require File.dirname(__FILE__) + '/common'
require File.dirname(__FILE__) + '/common/http_server'
require File.dirname(__FILE__) + '/client/connection'
require File.dirname(__FILE__) + '/client/callbacks'
require File.dirname(__FILE__) + '/client/file_info'
require File.dirname(__FILE__) + '/client/file_service'
require File.dirname(__FILE__) + '/client/http_handler'
=end

module PDTP
  # PDTP::Client provides an interface for accessing resources on PDTP servers
  class Client
    # None of these should be publically accessible, and will be factored away in time
    # attr_reader :connection, :client_id, :listen_port, :file_service, :transfers

    # Create a PDTP::Client object for accessing the PDTP server at the given host and port
    def initialize(host, port = PDTP::DEFAULT_PORT, options = {})
      @host, @port = host, port
            
      @listen_addr = options[:listen_addr] || '0.0.0.0'
      @listen_port = options[:listen_port] || 60860
      
      @file_service = PDTP::Client::FileService.new
      @transfers = []

      # Start a Mongrel server on the specified port
      # FIXME: Better handling is needed if the desired port is in use
      @http_server = Mongrel::HttpServer.new @listen_addr, @listen_port

      @client_id = Digest::MD5.hexdigest "#{Time.now.to_f}#{$$}"

      #@@log.info "listening on port #{@listen_port}"
      @http_handler = HttpHandler.new(self)
      @http_server.register '/', @http_handler
    end

    # Connect to the PDTP server. This is a blocking call which runs the client event loop
    def connect(callbacks = nil)
      callbacks = Callbacks.new if callbacks.nil?
      
      unless callbacks.is_a?(Callbacks)
        raise ArgumentError, "callbacks must be an instance of PDTP::Client::Callbacks"
      end
                
      # Run the EventMachine reactor loop
      EventMachine.run do
        @http_server.run_evented
        @connection = EventMachine.connect(@host, @port, Connection, self, callbacks)

        #@@log.info "connecting with ev=#{EventMachine::VERSION}"
        #@@log.info "host= #{host} port=#{opts[:port]}"
      end
    end

    # Are we currently connected to a server?
    def connected?
      not @connection.nil?
    end

    # Retrieve the resource at the given path and write it to the given IO object
    def get(path, io, options = {})
      raise RuntimeError, "not connected to server yet" unless connected?
      
      path = '/' + path unless path[0] == ?/
      url = "http://#{@host}#{path}"
      filename = path.split('/').last
      
      # Register the file and its IO object with the local file service
      file_service.set_info url, FileInfo.new(filename, io)
      
      # Ask the server for some information on the file we want
      @connection.send_message :ask_info, :url => url

      # Request the file (should probably be done after receiving :tell_info)
      @connection.send_message :request, :url => url

      #@@log.info "This client is requesting"
    end
    
    # Stop the client event loop.  This only works within callbacks given to the #connect method
    def stop
      EventMachine.stop_event_loop
    end
  end
end