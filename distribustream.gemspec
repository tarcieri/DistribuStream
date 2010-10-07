require 'rubygems'

GEMSPEC = Gem::Specification.new do |s|
  s.name = "distribustream"
  s.version = "0.6.0-revactor"
  s.authors = ["Tony Arcieri", "Ashvin Mysore", "Galen Pahlke", "James Sanders", "Tom Stapleton"]
  s.email = "tony@clickcaster.com"
  s.date = "2008-1-21"
  s.summary = "DistribuStream is a fully open peercasting system allowing on-demand or live streaming media to be delivered at a fraction of the normal cost"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.0'

  # Gem contents
  s.files = Dir.glob("{bin,lib,conf,status}/**/*") + ['Rakefile', 'distribustream.gemspec']
  s.executables = %w{dstream dsclient}

  # Dependencies
  s.add_dependency("revactor", ">= 0.1.1")
  s.add_dependency("mongrel", ">= 1.1.2")

  # RubyForge info
  s.homepage = "http://distribustream.org"
  s.rubyforge_project = "distribustream"

  # RDoc settings
  s.has_rdoc = true
  s.rdoc_options = %w(--title PDTP --main README --line-numbers)
  s.extra_rdoc_files = ["COPYING", "README", "CHANGES", "pdtp-specification.xml"]
end
