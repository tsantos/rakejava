require 'rake'

Gem::Specification.new do |s| 
  s.name = "rakejava"
  s.version = "1.0.1"
  s.author = "Tom Santos"
  s.email = "santos.tom@gmail.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "Rake tasks for building Java stuff"
  s.files = ["README"] + FileList["lib/**/*"].to_a
  s.require_path = "lib"
end
