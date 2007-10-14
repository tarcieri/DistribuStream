require 'rubygems'

GEMSPEC = Gem::Specification.new do |s|
  s.name = "distribustream"
  s.version = "0.1.0"
  s.date = "2008-10-11"
  s.summary = "DistribuStream is a fully open peercasting system allowing on-demand or live streaming media to be delivered at a fraction of the normal cost"
  s.email = "tony@clickcaster.com"
  s.homepage = "http://distribustream.rubyforge.org"
  s.rubyforge_project = "distribustream"
  s.has_rdoc = true
  s.rdoc_options = ["--exclude", "definitions", "--exclude", "indexes"]
  s.extra_rdoc_files = ["COPYING", "README", "CHANGES"]
  s.authors = ["Tony Arcieri", "Ashvin Mysore", "Galen Pahlke", "James Sanders", "Tom Stapleton"]
  s.files = Dir.glob("{bin,lib}/**/*")
  s.executables = ["dstream_client", "dstream_fileservice", "dstream_server"]
  s.add_dependency("eventmachine", ">= 0.9.0")
  s.add_dependency("mongrel", ">= 1.0.1")
  s.add_dependency("json", ">= 1.1.0")
end
