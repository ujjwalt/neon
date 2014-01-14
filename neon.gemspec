lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'neon/version'

Gem::Specification.new do |s|
  s.name     = "neon"
  s.version  = Neon::VERSION
  s.required_ruby_version = ">= 1.9.2"

  s.authors  = "Ujjwal Thaakar"
  s.email    = 'ujjwalthaakar@gmail.com'
  s.homepage = "http://github.com/ujjwalt/neon"
  s.summary = "Sleek ruby bindings for Neo4J"
  s.description = <<-EOF
  Neon is fast, minimal ruby binding for the Neo4J.
  It provides a simple api to manipulate a Neo4J database instance hosted on a server or running as an embedded instance.
  EOF

  s.require_path = 'lib'
  s.files = Dir.glob("{bin,lib,config}/**/*") + %w(README.md Gemfile neon.gemspec)

  # Development dependencies
  s.add_development_dependency "os", "~> 0.9"
  s.add_development_dependency "rake", "~> 10.1"
  s.add_development_dependency "rspec", "~> 2.8"
  s.add_development_dependency "yard", "~> 0.8"

  s.add_dependency "httparty", "~> 0.12"
  s.add_dependency "json", "~> 1.8"
  s.add_dependency "neo4j-cypher", "~> 1.0"
  s.add_dependency "neography", "~> 1.3"
end
