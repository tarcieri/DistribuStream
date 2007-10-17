#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

module PDTP
  class FileBuffer
    def initialize(io)
      @io = io
      @entries = []
      @total_written = 0
    end
    
    def write(start_pos, data)
      if start_pos > @total_written
      elsif start_pos == @total_written
      else      
      end
    end
  end
end