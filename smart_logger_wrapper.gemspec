# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smart_logger_wrapper/version'

Gem::Specification.new do |spec|
  spec.name          = "smart_logger_wrapper"
  spec.version       = SmartLoggerWrapper::VERSION
  spec.authors       = ["Akihiro Katsura"]
  spec.email         = ["info@kats.la"]

  spec.summary       = %q{SmartLoggerWrapper adds some useful features to the Ruby Logger or a subclass.}
  # spec.description   = %q{SmartLoggerWrapper adds some useful features to the Ruby Logger or a subclass.}
  spec.homepage      = "https://github.com/akeyhero/smart_logger_wrapper"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry-byebug", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.14"
end
