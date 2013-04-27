$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "apple_epf_importer/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "apple_epf_importer"
  s.version     = AppleEpfImporter::VERSION
  s.authors     = ["Barnabas Birmacher", "Viktor Benei"]
  s.email       = ["birmacher@gmail.com", "viktorbenei@live.com"]
  s.homepage    = "http://goappstream.com"
  s.summary     = "Simple importer for Apple's EPF files."
  s.description = "The gem only imports the selected files, does not store them in the database."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.3"
  s.add_dependency "curb"
end
