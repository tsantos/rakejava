require 'rubygems'
require 'rake/gempackagetask'
require 'rake/clean'

GEM         = 'rakejava'
GEM_VERSION = '1.3.1'

spec = Gem::Specification.new do |s|
  s.author      = 'Tom Santos'
  s.email       = 'santos.tom@gmail.com'
  s.homepage    = "http://github.com/tsantos/rakejava"
  s.name        = GEM
  s.version     = GEM_VERSION

  s.summary     = "Rake tasks for building Java stuff (javac and jar)"
  s.description = s.summary
  s.has_rdoc    = false
  s.platform    = Gem::Platform::RUBY

  s.add_dependency 'rake'
  s.files = %w[
    README.markdown
    lib/rakejava.rb
  ]
end

Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end 

desc "Installs the gem locally"
task :install => :gem do |t|
  system "sudo gem install pkg/#{GEM}-#{GEM_VERSION}.gem"
end

desc "Pushes the gem to gemcutter"
task :push => :gem do |t|
  system "gem push pkg/#{GEM}-#{GEM_VERSION}.gem"
end

task :default => :gem

CLEAN.include 'pkg'
