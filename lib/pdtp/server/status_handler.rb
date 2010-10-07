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

require 'revactor/mongrel'
require 'erb'

require File.dirname(__FILE__) + '/status_helper'

module PDTP
  class Server
    # A Mongrel::HttpHandler for generating the status page
    class StatusHandler < Mongrel::HttpHandler
      include StatusHelper
      
      def initialize(vhost, dispatcher)
        @vhost, @dispatcher = vhost, dispatcher
        @status_erb = File.expand_path(File.dirname(__FILE__) + '/../../../status/index.erb')
      end

      # Process an incoming request to generate the status page
      def process(request, response)
        @dispatcher << T[:ask_status, Actor.current]
        @status = Actor.receive do |filter| 
          filter.when(T[:tell_status, Object]) { |_, st| st }
        end
        
        p @status
        
        response.start(200) do |head, out|
          out.write begin
            # Read the status page ERb template
            erb_data = File.read @status_erb
            
            # Render the status ERb template
            html = ERB.new(erb_data).result(binding)
            
            # Call reset_cycle from the StatusHelper to reset cycle() calls
            reset_cycle
            
            # Return output html
            html
          rescue => e
            "Exception: #{e}\n#{e.backtrace.join("\n")}"
          end
        end    
      end      
    end
  end
end
