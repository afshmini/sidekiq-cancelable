# frozen_string_literal: true

module Sidekiq
  VERSION = "0.1.0"
  MAJOR = 0

  def self.gem_version
    Gem::Version.new(VERSION)
  end
end
