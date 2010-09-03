# RakeJava is a set of custom rake tasks for building Java projects
#
# Author: Tom Santos
# http://github.com/tsantos/rakejava

=begin
Copyright 2009, 2010 Tom Santos

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

module RakeJavaUtil
   def pushd dir
      pushd_stack.unshift(Dir.pwd)
      cd dir
   end

   def popd
      cd pushd_stack.shift
   end
   
   def pushd_stack
      unless defined?(@pushd_stack)
         @pushd_stack = []
      end
      @pushd_stack
   end

   def winderz?
      RUBY_PLATFORM =~ /(win|w)32$/
   end
   
   def path_esc str_ary
      if !winderz?
         str_ary.map { |str| str.gsub('$', '\$').gsub(' ', '\ ') }
      else
         str_ary
      end
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

class JarFiles < Rake::FileList
   include RakeJavaUtil
   
   attr_accessor :root
   
   def initialize *args
      @root = args.shift.sub(%r[/+$], '') # remove trailing slashes
      @resolved = false
      super
   end
   
   def resolve
      unless @resolved
         @resolved = true
         pushd @root
         super
         puts "Resolving #{self.class.name} list"
         @items.map! { |i| "#{@root}#{File::SEPARATOR}#{i}" }
         popd
      end
      self
   end
end

class CopyFiles < JarFiles
   def initialize *args
      super
      @flattened = false
      @dest = nil
   end

   def flatten!
      @flattened = true
      self
   end

   def flattened?
      @flattened
   end

   def dest_path
      @dest
   end

   def dest subdir
      @dest = subdir.sub(%r[/+$], '') # remove trailing slashes
      self
   end
end

module RakeJava
   class JavacTask < Rake::Task
      include RakeJavaUtil
      
      attr_accessor :bootpath, :classpath, :src, :dest, :args
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
            srcpath = @src.map { |src| src.root }

            @bootpath.flatten!
            @classpath.flatten!
            
            cmd = "javac"
            cmd << " -bootclasspath #{path_sep(@bootpath)}" unless @bootpath.empty?
            cmd << " #{@args}"                              if @args
            cmd << " -classpath #{path_sep(@classpath)}"    unless @classpath.empty?
            cmd << " -g"                                    if @debug
            cmd << " -source #{@src_ver}"                   if @src_ver
            cmd << " -target #{@dest_ver}"                  if @dest_ver
            cmd << " -sourcepath #{path_sep(srcpath)}"      if srcpath
            cmd << " -d #{@dest}"                           if @dest
            cmd << " #{space_sep(files)}"
            
            max_cmd_len = 500
            if cmd.length < max_cmd_len
               puts cmd
            else
               puts cmd[0..max_cmd_len] + "..."
            end
            puts "Compiling #{files.length} file(s)"
            system "#{cmd}"
            puts
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
            classfiles = []
            
            if @dest
               base_path = parent[sources.root.length+1..-1]
               classfiles = Dir["#{@dest}/#{base_path}/#{base}*.class"]
            else
               # Look next to it
               classfiles = Dir["#{parent}/#{base}*.class"]
            end
               
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
         changed
      end
   end
   
   class JarTask < Rake::Task
      include RakeJavaUtil
      
      attr_accessor :files, :main_class, :manifest, :sign_info
      
      def initialize name, app
         super
         @files = []

         # Deal with namespaces.  I have no idea if this 
         # is a total hack.
         name =~ /.*\:(.*)/
         if $1   
            @real_name = $1
         else    
            @real_name = name
         end     
      end
      
      def execute args=nil
         super

         flags = "cf"
         jar = File.expand_path(@real_name)
       
         all_files = []
         @files.each do |file_list|
            all_files << file_list.to_a
         end
         all_files.flatten!
         
         actual_files = []
         all_files.each do |item|
            if File.directory?(item)
               actual_files << Dir["#{item}/**/*"].to_a.select { |f| File.file?(f) }
            else
               actual_files << item
            end
         end
         actual_files.flatten!
         actual_files.uniq!

         # Bail if there's already a jar file and none of the
         # source files are newer.
         if uptodate?(jar, actual_files)
            puts "Jar file is up to date. Nothing to do."
            return
         end
         
         if @main_class
            unless @manifest
               @manifest = {}
            end
            @manifest["Main-Class"] = @main_class
         end
         manifest_path = " "
         if @manifest
            flags << "m"
            if @manifest.kind_of? Hash
               manifest_path << create_manifest
            elsif @manifest.kind_of? String
               manifest_path << File.expand_path(@manifest)
            end
         end
         
         cmd = "jar #{flags} #{@real_name}#{manifest_path}"
         
         @files.each do |file_list|
            # Hack time because the jar command is busted.  Every arg after the
            # first file listed after a -C needs to have paths relative to the
            # command-launch rather than the -C specified dir.  The first file arg
            # after a -C works but subsequent ones fail.
            fixed_list = file_list.to_a
            unless fixed_list.empty?
               fixed_list[0].sub!(%r[^#{file_list.root}/], '')
            end

            cmd << " -C #{file_list.root} #{space_sep(path_esc(fixed_list))}"
         end
         
         max_cmd_len = 500
         if cmd.length < max_cmd_len
            puts cmd
         else
            puts cmd[0..max_cmd_len] + "..."
         end

         system "#{cmd}"
         puts
         
         # Now, sign the jar if we're asked to.  This only supports the
         # arguments that I need for my project at the moment.
         if @sign_info
            cmd = "jarsigner"
            cmd << " -storetype #{@sign_info[:store_type]}"
            cmd << " -keystore #{@sign_info[:key_store]}"
            cmd << " -storepass #{@sign_info[:store_pass]}"
            cmd << " #{@real_name}"
            cmd << " #{@sign_info[:alias]}"
            puts squelch_pass(cmd, @sign_info[:store_pass])
            system "#{cmd}"
            puts
         end
      end

      protected
      def squelch_pass cmd, pass
        squelch = '*' * pass.length
        cmd.gsub(/#{pass}/, squelch)
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
         
         file = Tempfile.new("manifest", "/tmp")
         File.open(file.path, "w") do |f|
            f.puts(manifest)
         end
                  
         file.path
      end
   end

   # A simple class for copying files from various places to
   # a single target directory. You can tell it to just copy
   # files if they're newer than the target version.
   #
   class Copier
      attr_accessor :files

      def initialize dest_dir, &block
         @files = []
         @dest_dir = dest_dir.sub(%r[/+$], '') # remove trailing slashes
         @check_date = true
         block.call(self)
      end

      def force
         @check_date = false
      end

      def copy
         dirs = Set.new

         @files.each do |copy_files|
            src_files = copy_files.to_a

            if copy_files.kind_of?(CopyFiles)
               partials = src_files.map { |f| f.sub(%r[^#{copy_files.root}/], '') } 
            else
               partials = src_files
            end

            partials.each do |part|
               if copy_files.kind_of?(CopyFiles)
                  src_path = "#{copy_files.root}/#{part}"
                  dest_dir = @dest_dir + (copy_files.dest_path ? "/#{copy_files.dest_path}" : '')
                  if copy_files.flattened?
                     dest_path = "#{dest_dir}/#{File.basename(src_path)}"
                  else
                     dest_path = "#{dest_dir}/#{part}"
                  end
               else
                  src_path = part
                  dest_path = "#{@dest_dir}/#{part}"
               end

               if File.directory?(src_path)
                  next
               end

               if @check_date && File.exist?(dest_path)
                  src_time = File.mtime(src_path)
                  dest_time = File.mtime(dest_path)
                  if src_time <= dest_time
                     next
                  end
               end

               # Ensure the path
               parent = File.dirname(dest_path)
               unless dirs.include?(parent)
                  dirs << parent
                  mkdir_p parent
               end

               # Copy the file
               cp src_path, dest_path
            end
         end
      end
   end
end

def javac *args, &block
   RakeJava::JavacTask.define_task(*args, &block)
end

def jar *args, &block
   RakeJava::JarTask.define_task(*args, &block)
end

def copy_to dest_dir, &block
   copier = RakeJava::Copier.new(dest_dir, &block)
   copier.copy()
end

# vim: filetype=ruby tabstop=3 expandtab 
