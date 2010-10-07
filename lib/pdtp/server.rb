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
require 'revactor/mongrel'
require 'logger'

require File.dirname(__FILE__) + '/common'
require File.dirname(__FILE__) + '/server/status_handler'
require File.dirname(__FILE__) + '/server/dispatcher'
require File.dirname(__FILE__) + '/server/peer'
require File.dirname(__FILE__) + '/server/file_service'

module PDTP
  # PDTP::Server provides an interface for creating a PDTP server
  class Server
    attr_reader :addr, :port
    
    # Create a new PDTP::Server which will listen on the given address and port
    def initialize(host, pdtp_port = DEFAULT_PORT, http_port = pdtp_port + 1)
      @host, @addr, @port, @http_port = host, IPSocket.getaddress(host), pdtp_port, http_port
      
      @file_service = FileService.new @host, @http_port
      @dispatcher = Dispatcher.spawn self, @file_service
    end
    
    # Run a web server to display statistics on the given address and port 
    def enable_status_page(path = '/status')
      # Strip trailing slash (if present)
      path.sub!(/\/$/, '')
      
      log "status at http://#{@addr}:#{@http_port}#{path}/"
      
      # Redirect requests without a trailing slash
      http_server.register path, Mongrel::RedirectHandler.new(path + '/')
      
      # Register the status handler
      http_server.register path + '/', StatusHandler.new(@host, @dispatcher), true
      
      # Serve status images
      images = Mongrel::DirHandler.new(File.dirname(__FILE__) + '/../../status/images', false)
      http_server.register path + '/images', images
      
      # Serve status stylesheets
      styles = Mongrel::DirHandler.new(File.dirname(__FILE__) + '/../../status/stylesheets', false)
      http_server.register path + '/stylesheets', styles
    end
    
    def enable_file_service(path, options = {})
      @file_service.enable path, options
      http_server.register '/', FileService::Handler.new(@dispatcher, @file_service)
    end
    
    # Enable logging
    def enable_logging(logger = nil)
      @log = logger || default_logger
    end
    
    # Run the PDTP server event loop
    def run
      Actor.spawn { http_server.start } if @http_server
      
      listen_sock = Actor::TCP.listen @addr, @port, :filter => T[:packet, 2]
      log "accepting connections on #{@addr}:#{@port}"
      
      while true 
        Actor.spawn(listen_sock.accept) { |sock| start_connection sock }
      end
    end
    
    # Write a message to the server log
    def log(message, type = :info)
      return unless @log
      @log.send type, message
    end
    
    # Write a debug message to the server log (ignored in quiet mode)
    def debug(message)
      log message
      #log message, :debug
    end
    
    #########
    protected
    #########
        
    def start_connection(sock)
      peer = Peer.new(sock)
      @dispatcher << T[:peer_connect, peer]
      
      sock.controller = Actor.current
      sock.active = :once
      
      loop do
        Actor.receive do |f|
          f.when(T[:tcp, sock, Object]) do |_, _, message|
            @dispatcher << T[:message, Actor.current, peer, JSON.parse(message)]
          
            # Wait for acknowledgement that the message has been dispatched
            Actor.receive do |f|
              f.when(:ok) { sock.active = :once }
              f.when(T[:error, Object]) { |_, ex| raise ex }
            end
          end
        
          f.when(T[:tcp_closed, sock]) do
            raise EOFError, "connection closed"
          end
        end
      end
    rescue => ex
      case ex
      when ProtocolError
        peer.fatal_error ex.to_s
      when EOFError
      else debug "#{ex.class}: #{[ex, *ex.backtrace].join("\n\t")}"
      end
      
      sock.close
      @dispatcher << T[:peer_closed, peer]
    end
    
    def default_logger
      STDERR.sync = true
      logger = Logger.new STDERR
      logger.datetime_format = "%H:%M:%S "
      logger
    end
    
    # Start Mongrel on the specified port
    def http_server
      @http_server ||= Mongrel::HttpServer.new @addr, @http_port
    end
  end
end
