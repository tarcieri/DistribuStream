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

#require 'active_support'

# Namespace for all PDTP components
module PDTP
  PDTP::VERSION = '0.6.0-revactor' unless defined? PDTP::VERSION
  def self.version() VERSION end

  PDTP::DEFAULT_PORT = 6086 unless defined? PDTP::DEFAULT_PORT
  def self.default_port() DEFAULT_PORT end
    
  class ProtocolError < StandardError; end
end
