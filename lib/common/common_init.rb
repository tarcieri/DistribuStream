#Provides functions used for initialization by both the client and server

require 'optparse'
require 'logger'
require File.dirname(__FILE__)+'/pdtp_protocol'

STDOUT.sync=true
STDERR.sync=true

@@log=Logger.new(STDOUT)
@@log.datetime_format=""


@@config={
  :host=>"127.0.0.1", #server host
  :port=>6000, #server port
  :listen_port=> 8000, #client listen port
  :file_root=>File.dirname(__FILE__)+'/../../../testfiles',
  :quiet=>true,
  :chunk_size=>5000,
  :provide_hostname=>"clickcaster.com",
  :request_url=>"http://clickcaster.com/test.mp3"
}

@types={
  :host=>:string,
  :port=>:int,
  :listen_port=>:int,
  :file_root=>:string,
  :quiet=>:bool,
  :chunk_size=>:int,
  :provide_hostname=>:string,
  :request_url=>:string
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
  if config_filename.nil? then
    puts "No config file specified. Using defaults."
    return
  end

  confstr=File.read(config_filename) rescue nil
  if confstr.nil? then
    puts "Unable to open config file: #{config_filename}"
    exit
  end

  begin
    new_config=eval(confstr)
    @@config.merge!(new_config)
  rescue Exception=>e
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
    if type.nil? then
      puts "Unknown parameter: #{key}"
      exit
    end

    unless PDTPProtocol::obj_matches_type?(val,type) then
      puts "Parameter: #{key} is not of type: #{type}"
      exit
    end
  end


end

#responds to config options that are used by both client and server
def handle_config_options
  @@log.level=Logger::INFO if @@config[:quiet]  
  
end
