# frozen_string_literal: true

require_relative 'lib/c2ffi/version'

Gem::Specification.new do |spec|
  spec.name         = 'c2ffi'
  spec.version      = C2FFI::VERSION
  spec.authors      = ['Ryan Pavlik']
  spec.email        = ['rpavlik@gmail.com']

  spec.summary      = 'C2FFI for Ruby-FFI'
  spec.description  = 'Import C2FFI JSON to ruby/ffi'
  spec.homepage     = 'https://github.com/rpav/c2ffi-ruby'
  spec.license      = 'LGPL-2'

  spec.files        = Dir['*.{md,txt}', '{lib}/**/*']
  spec.require_path = ['lib']
  spec.bindir       = 'exe'
  spec.executables  = ['c2ffi-ruby']

  spec.required_ruby_version = '>= 2.4'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
end
