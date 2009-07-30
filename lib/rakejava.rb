# RakeJava is a set of custom rake tasks for building Java projects
#
# Author: Tom Santos
# http://github.com/tsantos/rakejava/tree/master

=begin
Copyright 2009 Tom Santos

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

require 'rake'
require 'set'
require 'tempfile'

class Sources < Rake::FileList
	attr_accessor :root
	
	def initialize *args
		@root = args.shift
		args = args.map { |arg| "#{@root}/#{arg}" }
		super
	end
		
	class << self
		def [] *args
			new(*args)
		end
	end
end

module RakeJava
	class RakeJavaTask < Rake::Task
		def initialize name, app
			super
			@pushd_stack = []
		end

		def pushd dir
			@pushd_stack.unshift(`pwd`.chop)
			cd dir
		end

		def popd
			cd @pushd_stack.shift
		end

		def path_sep str_ary
			separate(str_ary, File::PATH_SEPARATOR)
		end
		def space_sep str_ary
			separate(str_ary, ' ')
		end

		def separate str_ary, sep
			result = ""
			str_ary.each { |str| result << "#{str}#{sep}" }
			result.chop!
		end
	end
	
	class JavacTask < RakeJavaTask
		attr_accessor :srcpath, :bootpath, :classpath, :src, :dest, :args
		attr_accessor :src_ver, :dest_ver, :debug
		
		def initialize name, app
			super
			@src = []
			@srcpath = []
			@bootpath = []
			@classpath = []
		end
		
		def execute args=nil
			super
			files = src_files
			
			unless files.empty?
				cmd = "javac"
				cmd << " -bootclasspath #{path_sep(@bootpath)}"	unless @bootpath.empty?
				cmd << " #{@args}"										if @args
				cmd << " -classpath #{path_sep(@classpath)}"		unless @classpath.empty?
				cmd << " -g"												if @debug
				cmd << " -source #{@src_ver}"							if @src_ver
				cmd << " -target #{@dest_ver}"						if @dest_ver
				cmd << " -sourcepath #{path_sep(@srcpath)}"		unless @srcpath.empty?
				cmd << " -d #{@dest}"									if @dest
				cmd << " #{space_sep(files)}"
				
				max_cmd_len = 500
				if cmd.length < max_cmd_len
					puts cmd
				else
					puts cmd[0..max_cmd_len] + "..."
				end
				puts "Compiling #{files.length} file(s)"
				puts `#{cmd}`
			else
				puts "No files to compile"
			end
			
		end
		
		def src_files
			files = []
			
			@src.each do |source|
				files << changed_only(source)
			end
			
			files.flatten
		end
		
		def changed_only sources
			# Retuns the files that have newer .java files than .class files
			changed = []
			sources.each do |src_file|
				mod_time = File.mtime(src_file)
				base = File.basename(src_file, ".java")
				parent = File.dirname(src_file)
				if @dest
					# Figure out how to find the matching class files
					changed << src_file
				else
					# Look next to it
					classfiles = Dir["#{parent}/#{base}*.class"]
					
				 	unless classfiles.empty?
						classfiles.each do |classfile|
							if File.mtime(classfile) < mod_time
								changed << src_file
								break
							end
						end
					else
						changed << src_file
					end
				end
			end
			changed
		end
	end
	
	class JarTask < RakeJavaTask
		attr_accessor :root, :files, :manifest
		
		def initialize name, app
			super
			@files = []
		end
		
		def execute args=nil
			files = ""
			pushd @root
			FileList[@files].to_a.each do |file|
				
			end
			`jar cf #{@name} #{files}`
			popd
		end
		
		def files files
			if files.kind_of? Array
				files.each { |item| @contents << item }
			else
				@contents << files
			end
		end
		
		protected
		def create_manifest
			manifest = [
				"Manifest-Version: 1.0",
				"Created-By: rakejava"
			]
			
			@manifest.each do |key, value|
				manifest << "#{key}: #{value}"
			end
			
			file = Tempfile.new("manifest", "/tmp") do |f|
				f.puts(manifest)
			end
			
			File.expand_path(file)
		end
	end
end

def javac *args, &block
	RakeJava::JavacTask.define_task(*args, &block)
end

def jar *args, &block
	RakeJava::JarTask.define_task(*args, &block)
end
