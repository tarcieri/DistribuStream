require 'rake'
require 'rake/rdoctask'
require 'rake/gempackagetask'

# Default Rake task
task :default => :rdoc

# RDoc
Rake::RDocTask.new(:rdoc) do |task|
 task.rdoc_dir = 'doc'
 task.title    = 'DistribuStream'
 task.rdoc_files.include('bin/**/*.rb')
 task.rdoc_files.include('lib/**/*.rb')
 task.rdoc_files.include('simulation/**/*.rb')
  task.rdoc_files.include('test/**/*.rb')
end

# GemSpec
spec = Gem::Specification.new do |s|
  s.name = %q{distribustream}
  s.version = '0.1.0'
  s.date = %q{2008-10-11}
  s.summary = %q{DistribuStream is a fully open peercasting system allowing on-demand or live streaming media to be delivered at a fraction of the normal cost}
  s.email = %q{tony@clickcaster.com}
  s.homepage = %q{http://distribustream.rubyforge.org}
  s.rubyforge_project = %q{distribustream}
  s.has_rdoc = true
  s.rdoc_options = ["--exclude", "definitions", "--exclude", "indexes"]
  s.extra_rdoc_files = ["README", "CHANGES"]
  s.authors = ["Tony Arcieri", "Ashvin Mysore", "Galen Pahlke", "James Sanders", "Tom Stapleton"]
  s.files = ["Rakefile", "lib", "lib/buftok.rb"]
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

# RSpec
begin
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new(:spec) do |task|
  task.spec_files = FileList['**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:specfs) do |task|
  task.spec_files= FileList['**/*_spec.rb']
  task.spec_opts="-f s".split
end

Spec::Rake::SpecTask.new(:spec_coverage) do |task|
  task.spec_files = FileList['**/*_spec.rb']
  task.rcov = true
end
rescue LoadError
end


