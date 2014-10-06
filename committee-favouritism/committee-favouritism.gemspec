# -*- encoding: utf-8 -*-
require File.expand_path('../lib/committee-favouritism/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Georgios Gousios", "Panos Louridas"]
  gem.email         = ["gousiosg@gmail.com", "louridas@gmail.com"]
  gem.description   = %q{Study of whether inclusion to a scientific committee increases the changes of being cited}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(tests|spec|features)/})
  gem.name          = "committee-favouritism"
  gem.require_paths = ["lib"]
  gem.version       = CommitteeFavouritism::VERSION

  gem.add_dependency "trollop", ['>= 1.16']
  gem.add_dependency "json", ['>= 1.6']
  gem.add_dependency "hpricot", ['>= 0.8.6']
end
