#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Manual testing script for job cancellation
# Usage: ruby test_manual.rb

require 'sidekiq'
require 'sidekiq/api'

# Define a long-running job for testing
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

puts "=" * 60
puts "Sidekiq Job Cancellation Manual Test"
puts "=" * 60
puts

# Check if Redis is available
begin
  Sidekiq.redis { |conn| conn.ping }
  puts "✓ Redis connection: OK"
rescue => e
  puts "✗ Redis connection failed: #{e.message}"
  puts "  Make sure Redis is running on localhost:6379"
  exit 1
end

# Test 1: Check WorkSet API
puts "\n1. Testing WorkSet#cancel_job API..."
workset = Sidekiq::WorkSet.new
result = workset.cancel_job("test-jid-123")
puts "   Cancel non-existent job: #{result} (should be false)"

# Test 2: Check cancellation flag setting
puts "\n2. Testing cancellation flag in Redis..."
test_jid = "manual-test-#{Time.now.to_i}"
workset.cancel_job(test_jid)
flag_exists = Sidekiq.redis { |conn| conn.exists?("cancelled:#{test_jid}") }
puts "   Cancellation flag set: #{flag_exists} (should be true)"

# Clean up test flag
Sidekiq.redis { |conn| conn.del("cancelled:#{test_jid}") }

# Test 3: Enqueue a job
puts "\n3. Enqueueing a test job..."
jid = LongRunningTestJob.perform_async(30)
puts "   Job enqueued with JID: #{jid}"
puts "   Queue: default"

# Instructions
puts "\n" + "=" * 60
puts "Next Steps:"
puts "=" * 60
puts "1. Start Sidekiq in another terminal:"
puts "   bundle exec sidekiq"
puts
puts "2. Wait for the job to start running"
puts
puts "3. Open the Sidekiq Web UI:"
puts "   - If using Rails: http://localhost:3000/sidekiq/busy"
puts "   - Or start a simple Rack server (see TESTING.md)"
puts
puts "4. Navigate to the 'Busy' tab"
puts
puts "5. Find your job (JID: #{jid}) and click 'Cancel'"
puts
puts "6. Check the Sidekiq logs - you should see:"
puts "   'Job #{jid} cancellation detected, interrupting...'"
puts "=" * 60

