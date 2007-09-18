require 'rake'
require 'rake/rdoctask'

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

Rake::RDocTask.new(:rdoc) do |task|
 task.rdoc_dir = 'doc'
 task.title    = 'DistribuStream'
 task.rdoc_files.include('bin/**/*.rb')
 task.rdoc_files.include('lib/**/*.rb')
 task.rdoc_files.include('simulation/**/*.rb')
  task.rdoc_files.include('test/**/*.rb')
end

task :default => :rdoc
