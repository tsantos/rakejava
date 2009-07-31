require 'rake'

Gem::Specification.new do |s| 
	s.name = "rakejava"
	s.version = "1.0.2"
	s.date = "2009-07-30"
	s.rubygems_version = "1.3.0"
	s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

	s.author = "Tom Santos"
	s.email = "santos.tom@gmail.com"
	s.platform = Gem::Platform::RUBY
	s.description = "Rake tasks for building Java stuff"
	s.summary = "Rake tasks for building Java stuff"
	s.files = ["README"] + FileList["lib/**/*"].to_a
	s.require_path = "lib"
	s.homepage = "http://github.com/tsantos/rakejava"
end
