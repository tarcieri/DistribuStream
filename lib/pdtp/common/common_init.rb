#--
# Copyright (C) 2006-07 ClickCaster, Inc. (info@clickcaster.com)
# All rights reserved.  See COPYING for permissions.
# 
# This source file is distributed as part of the 
# DistribuStream file transfer system.
#
# See http://distribustream.rubyforge.org/
#++

#Provides functions used for initialization by both the client and server

require 'optparse'
require 'logger'

require File.dirname(__FILE__) + '/protocol'

STDOUT.sync=true
STDERR.sync=true

@@log=Logger.new(STDOUT)
@@log.datetime_format=""

@@config = {
  :host             => '0.0.0.0',
  :port             => 6086, #server port
  :listen_port      => 8000, #client listen port
  :file_root        => '.',
  :chunk_size       => 5000,
  :quiet            => true
}

@types = {
  :host             => :string,
  :port             => :int,
  :listen_port      => :int,
  :file_root        => :string,
  :quiet            => :bool,
  :chunk_size       => :int,
  :provide_hostname => :string,
  :request_url      => :string
}

#prints banner and loads config file
def common_init( program_name)
  config_filename=nil
  OptionParser.new do |opts|
    opts.banner = "Usage: #{program_name} [options]"
    opts.on("--config CONFIGFILE", "Load specified config file.") do |c|
      config_filename=c
    end
    opts.on("--help", "Prints this usage info.") do
      puts opts
      exit
    end
  end.parse!      

  puts "#{program_name} starting. Run '#{program_name} --help' for more info."

  load_config_file(config_filename)

  begin
    @@config[:file_root]=File.expand_path(@@config[:file_root])
  rescue 
    puts "Invalid path specified for file_root"
    return
  end

  puts "@@config=#{@@config.inspect}"
  validate_config_options
  handle_config_options
end

#loads a config file specified by config_filename
def load_config_file(config_filename)
  if config_filename.nil?
    puts "No config file specified. Using defaults."
    return
  end

  confstr=File.read(config_filename) rescue nil
  if confstr.nil?
    puts "Unable to open config file: #{config_filename}"
    exit
  end

  begin
    new_config = YAML.load confstr
    @@config.merge!(new_config)
    @@config[:provide_hostname] ||= @@config[:host] # Use host as vhost unless specified
  rescue Exception => e
    puts "Error parsing config file: #{config_filename}"
    puts e
    exit
  end

  puts "Loaded config file: #{config_filename}"
end

#make sure all the config options are of the right type
def validate_config_options
  @@config.each do |key,val|
    type=@types[key]
    if type.nil?
      puts "Unknown parameter: #{key}"
      exit
    end

    unless PDTP::Protocol.obj_matches_type?(val,type)
      puts "Parameter: #{key} is not of type: #{type}"
      exit
    end
  end
end

#responds to config options that are used by both client and server
def handle_config_options
  @@log.level=Logger::INFO if @@config[:quiet]  
end