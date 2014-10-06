# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activities/version'

Gem::Specification.new do |spec|
  spec.name          = 'activities'
  spec.version       = Activities::VERSION
  spec.authors       = ['Georgios Gousios']
  spec.email         = %w{gousiosg@gmail.com}
  spec.description   = %q{Process Github activity streams from issues and pull
                          requests as provided by the GHTorrent project.}
  spec.summary       = %q{Process Github activity streams}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'ghtorrent', '~> 0.8'
end
