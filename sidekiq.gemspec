require_relative "lib/sidekiq/version"

Gem::Specification.new do |gem|
  gem.authors = ["Afshmini", "Mike Perham"]
  gem.email = ["afshmini@gmail.com", "info@contribsys.com"]
  gem.summary = "Simple, efficient background processing for Ruby with job cancellation support"
  gem.description = "Simple, efficient background processing for Ruby. Fork of Sidekiq with the ability to cancel running jobs from the Web UI."
  gem.homepage = "https://github.com/afshmini/sidekiq-cancelable"
  gem.license = "LGPL-3.0"

  gem.executables = ["sidekiq", "sidekiqmon"]
  gem.files = %w[sidekiq.gemspec README.md Changes.md LICENSE.txt] + `git ls-files | grep -E '^(bin|lib|web)'`.split("\n")
  gem.name = "sidekiq-cancelable"
  gem.version = Sidekiq::VERSION
  gem.required_ruby_version = ">= 3.2.0"

  gem.metadata = {
    "homepage_uri" => "https://github.com/afshmini/sidekiq-cancelable",
    "bug_tracker_uri" => "https://github.com/afshmini/sidekiq-cancelable/issues",
    "documentation_uri" => "https://github.com/afshmini/sidekiq-cancelable",
    "changelog_uri" => "https://github.com/afshmini/sidekiq-cancelable/blob/main/Changes.md",
    "source_code_uri" => "https://github.com/afshmini/sidekiq-cancelable",
    "rubygems_mfa_required" => "true"
  }

  gem.add_dependency "redis-client", ">= 0.23.2"
  gem.add_dependency "connection_pool", ">= 2.5.0"
  gem.add_dependency "rack", ">= 3.1.0"
  gem.add_dependency "json", ">= 2.9.0"
  gem.add_dependency "logger", ">= 1.6.2"
end
