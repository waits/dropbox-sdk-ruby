Gem::Specification.new do |s|
  s.name        = 'dropbox-sdk-v2'
  s.version     = '0.0.3'
  s.summary     = 'Dropbox SDK v2'
  s.description = 'A Ruby library for the new Dropbox API.'
  s.authors     = ['Dylan Waits']
  s.email       = 'dylan@waits.io'
  s.files       = Dir["{lib}/**/*.rb", "LICENSE", "README.md"]
  s.require_paths = ['lib']
  s.homepage    = 'https://github.com/waits/dropbox-sdk-ruby'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.1.0'
  s.add_development_dependency 'minitest', '~> 5.9'
  s.add_development_dependency 'webmock', '~> 2.1'
  s.add_runtime_dependency 'http', '~> 2.0'
end
