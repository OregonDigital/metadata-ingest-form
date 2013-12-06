# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'metadata/ingest/form/version'

Gem::Specification.new do |spec|
  spec.name          = "metadata-ingest-form"
  spec.version       = Metadata::Ingest::Form::VERSION
  spec.authors       = ["Jeremy Echols"]
  spec.email         = ["jechols@uoregon.edu"]
  spec.summary       = %q{Form-backing objects for metadata models}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = ['README.md', 'LICENSE.txt'] + Dir['lib/**/*'] + Dir['spec/**/*']
  spec.test_files    = Dir['spec/**/*']
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
