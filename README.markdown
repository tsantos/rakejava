RakeJava is a ruby gem for use with Rake.  It lets you javac and jar Java files.

### Simple Example:

    require 'rakejava'
    require 'rake/clean'

    CLEAN.include 'build'

    task :default => "myproj.jar"

    jar "myproj.jar" => :compile do |t|
      t.files << JarFiles["build", "**/*.class"]
      t.main_class = 'org.whathaveyou.Main'
      t.manifest = {:version => '1.0.0'}
    end

    javac :compile => "build" do |t|
    	t.src << Sources["src", "**/*.java"]
    	t.src << Sources["test", "*.java"]
    	t.classpath << Dir["lib/**/*.{zip,jar}"]
    	t.dest = 'build'
    end

    directory "build"
    
-------------------------

# javac #

This task is a wrapper around Java's javac command and it supports most of the useful arguments.  Here are the attributes you can set:

* __src__ - a list of `Sources` objects.  See `Sources` below.
* __classpath__ - a list of directories and jar files.  You can use Dir.glob output.
* __dest__ - a list of `JarFiles` objects.  See `JarFiles` below.
* __bootpath__ - javac's bootclasspath.  It's a list like classpath.
* __src_ver__ - the JDK version of the source files.
* __target_ver__ - the target JDK you want the class files to be compatible with.
* __debug__ - if you want debug class files
* __args__ - a string containing any args you want to pass to javac.

### Sources ###

A `Rake::FileList` where the first argument specified is the top of a source tree.  Example:

    task.src << Sources["src", "**/*.java"]

-------------------------
# jar #

This task is a wrapper around Java's jar command and it supports all of its arguments.  The name of jar task is the jar file to emit.  Here are the attributes you can set:

* __files__ - a list of `JarFiles` objects.  See `JarFiles` below.
* __main_class__ - The main class for use with java -jar myapp.jar.
* __manifest__ - either a hash of key-value pairs to put into the manifest or a path to a manifest file.
* __sign_info__ - a hash detailing your signing information.  See `sign_info` below.

### JarFiles ###

A `Rake::FileList` where the first argument specified is the top directory of a source of files to jar.

    t.files << JarFiles["build", "**/*.class", "**/*.properties"]

### sign_info ###

Here's an example of using sign_info with the jar task:

    jar "myproj.jar" => :compile do |t|
      t.files << JarFiles["build", "**/*.class"]
      t.sign_info = {
      	:store_type	=> 'pkcs12',
      	:key_store	=> 'certs/keystore.p12',
      	:store_pass	=> 'you-know-yours',
      	:alias		=> 'you-know-yours'
      }
    end
