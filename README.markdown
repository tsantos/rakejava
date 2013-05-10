RakeJava is a ruby gem for use with Rake.  It lets you javac and jar Java files.

1.3.3 is the last release that works with Rake version 0.8.7.  Later releases work with 0.9.2.  The Rake folks sure made this hard given how many Rakefiles depend on 0.8.7.

1.3.6 makes JarFiles more robust so you can specify directories instead of the exhaustive list of files.  It also enables JRuby support.

1.3.7 fixes the jar task for Ruby >= 1.9

### Simple Example:


```ruby
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
```

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

```ruby
task.src << Sources["src", "**/*.java"]
```

-------------------------
# jar #

This task is a wrapper around Java's jar command and it supports all of its arguments.  The name of jar task is the jar file to emit.  Here are the attributes you can set:

* __files__ - a list of `JarFiles` objects.  See `JarFiles` below.
* __main_class__ - The main class for use with java -jar myapp.jar.
* __manifest__ - either a hash of key-value pairs to put into the manifest or a path to a manifest file.
* __sign_info__ - a hash detailing your signing information.  See `sign_info` below.

### JarFiles ###

A `Rake::FileList` where the first argument specified is the top directory of a source of files to jar.

```ruby
t.files << JarFiles["build", "**/*.class", "**/*.properties"]
```

### sign_info ###

Here's an example of using sign_info with the jar task:

```ruby
jar "myproj.jar" => :compile do |t|
  t.files << JarFiles["build", "**/*.class"]
  t.sign_info = {
  	:store_type	=> 'pkcs12',
  	:key_store	=> 'certs/keystore.p12',
  	:store_pass	=> 'you-know-yours',
  	:alias		=> 'you-know-yours'
  }
end
```

-------------------------
# copy_to #

This is a function that lets you copy files to a destination directory.  What makes this interesting is that by default it won't copy files unless they're newer.  Here's an example:

```ruby
task :copy_stuff do
  copy_to "/my/dest/dir" do |c|
    c.files << CopyFiles['build/java', '**/*.class'].exclude(/Test.class/)
    c.files << CopyFiles['lib', '**/*.{jar,zip}'].flatten!.dest('lib')
    c.files << Dir['ext/**/*.jar']
    c.force # Normally, only newer files get copied
  end
end
```

### CopyFiles ###

A `Rake::FileList` where the first argument is the parent directory of the files you want to specify for copying.  The files will end up in the destination with the same relative path to their original parent.

```ruby
c.files << CopyFiles['lib', '**/*.{jar,zip}']
```

You can use `CopyFiles` to collect files and then dump them all into the target directory by using `flatten!()`.

```ruby
c.files << CopyFiles['lib', '**/*.{jar,zip}'].flatten!
```

You can send all of the files specified in `CopyFiles` to a subdir of the target dir by using `dest()`.

```ruby
c.files << CopyFiles['lib', '**/*.{jar,zip}'].flatten!.dest('my_lib')
```
