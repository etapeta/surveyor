# Provide a simple gemspec so you can easily use your enginex
# project in your rails apps through git.
Gem::Specification.new do |s|
  s.name = "surveyor"
  s.summary = "Library to manage surveys."
  s.description = "Library to manage surveys."
  s.authors = ['cpetasecca@gmail.com']
  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
  s.version = "0.0.1"
end