#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Simple Rack server to test Sidekiq Web UI
# Usage: ruby test_web_ui.rb
# Then visit: http://localhost:4567/sidekiq/busy

require 'sidekiq/web'
require 'rack'
require 'rack/session'

# Define a test job
class LongRunningTestJob
  include Sidekiq::Job

  def perform(duration = 10)
    puts "[#{jid}] Job started, will run for #{duration} seconds..."
    duration.times do |i|
      sleep 1
      puts "[#{jid}] Running... #{i + 1}/#{duration}"
    end
    puts "[#{jid}] Job completed!"
  end
end

# Configure Sidekiq Web
Sidekiq::Web.configure do |config|
  config[:csrf] = false  # Disable CSRF for testing
end

# Create Rack app
app = Rack::Builder.new do
  use Rack::Session::Cookie, 
      secret: 'test-secret-key-for-sidekiq-web-ui-testing-only',
      same_site: true,
      httponly: true
  
  run Sidekiq::Web
end

puts "=" * 60
puts "Sidekiq Web UI Test Server"
puts "=" * 60
puts
puts "Starting server on http://localhost:4567"
puts
puts "Available routes:"
puts "  - Dashboard: http://localhost:4567/sidekiq"
puts "  - Busy (with cancellation): http://localhost:4567/sidekiq/busy"
puts "  - Queues: http://localhost:4567/sidekiq/queues"
puts
puts "To test cancellation:"
puts "  1. Enqueue a long-running job in another terminal:"
puts "     ruby test_manual.rb"
puts "  2. Start Sidekiq: bundle exec sidekiq"
puts "  3. Visit the Busy page and click Cancel"
puts
puts "Press Ctrl+C to stop the server"
puts "=" * 60
puts

# Start the server
Rack::Server.start(
  app: app,
  Port: 4567,
  Host: '0.0.0.0'
)

