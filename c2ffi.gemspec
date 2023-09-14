# frozen_string_literal: true

require_relative 'lib/c2ffi/version'

Gem::Specification.new do |spec|
  spec.name         = 'c2ffi'
  spec.version      = C2FFI::VERSION
  spec.authors      = ['kojix2', 'Ryan Pavlik']
  spec.email        = ['2xijok@gmail.com', 'rpavlik@gmail.com']

  spec.summary      = 'C2FFI for Ruby-FFI'
  spec.description  = 'Import C2FFI JSON to ruby/ffi'
  spec.homepage     = 'https://github.com/kojix2/c2ffi4rb'
  spec.license      = 'LGPL-2'

  spec.files        = Dir['*.{md,txt}', '{lib}/**/*']
  spec.require_path = ['lib']
  spec.bindir       = 'exe'
  spec.executables  = ['c2ffi4rb']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
end
