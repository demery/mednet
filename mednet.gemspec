# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mednet/version'

Gem::Specification.new do |spec|
  spec.name          = "mednet"
  spec.version       = Mednet::VERSION
  spec.authors       = ["Doug Emery"]
  spec.email         = ["emeryr@upenn.edu"]
  spec.summary       = %q{A short summary. Required.}
  # spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'htmlentities', '~> 4.3.3'

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
