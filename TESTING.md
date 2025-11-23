# Testing Job Cancellation Feature

This guide explains how to test the job cancellation feature both automatically and manually.

## Automated Tests

Run the test suite:

```bash
# Run all tests
bundle exec rake test

# Run only cancellation tests
bundle exec ruby -Itest test/job_cancellation_test.rb

# Run with verbose output
VERBOSE=1 bundle exec ruby -Itest test/job_cancellation_test.rb
```

The test suite includes:
- `WorkSet#cancel_job` method tests
- `Work#cancel!` method tests
- Web UI route tests
- Exception class tests

## Manual Testing

### Prerequisites

1. **Redis running**: Make sure Redis is running on `localhost:6379`
2. **Sidekiq process**: You'll need a Sidekiq worker process running

### Step 1: Create a Test Job

Create a file `test_job.rb`:

```ruby
# test_job.rb
require 'sidekiq'

class LongRunningJob
  include Sidekiq::Job

  def perform(duration = 10)
    puts "Job started, will run for #{duration} seconds..."
    duration.times do |i|
      sleep 1
      puts "Job running... #{i + 1}/#{duration}"
    end
    puts "Job completed!"
  end
end
```

### Step 2: Start Sidekiq

In one terminal, start Sidekiq:

```bash
# Make sure you're in the project directory
cd /home/afshmini/projects/afshmini/gems/sidekiq-cancelable

# Start Sidekiq (this will load the cancellation middleware automatically)
bundle exec sidekiq -r ./test_job.rb
```

### Step 3: Enqueue a Long-Running Job

In another terminal, enqueue a job:

```ruby
# In IRB or a Ruby console
require 'sidekiq'
require_relative 'test_job'

# Enqueue a job that will run for 30 seconds
LongRunningJob.perform_async(30)
```

Or create a simple script `enqueue_job.rb`:

```ruby
#!/usr/bin/env ruby
require 'sidekiq'
require_relative 'test_job'

# Enqueue a long-running job
jid = LongRunningJob.perform_async(30)
puts "Job enqueued with JID: #{jid}"
puts "Check the Sidekiq Web UI at http://localhost:4567/sidekiq/busy"
```

Run it:
```bash
ruby enqueue_job.rb
```

### Step 4: Access the Web UI

1. **Start the Web UI** (if not already running):

```ruby
# In IRB or a Ruby console
require 'sidekiq/web'
require 'rack'

# Simple Rack server
app = Rack::Builder.new do
  use Rack::Session::Cookie, secret: 'your-secret-key'
  run Sidekiq::Web
end

Rack::Server.start(app: app, Port: 4567)
```

Or use the Rails integration if you have a Rails app:

```ruby
# In config/routes.rb
require 'sidekiq/web'
mount Sidekiq::Web => '/sidekiq'
```

2. **Navigate to the Busy page**:
   - Open your browser to `http://localhost:4567/sidekiq/busy`
   - You should see your running job listed in the "Jobs" table

### Step 5: Cancel the Job

1. **Find your job** in the Jobs table on the Busy page
2. **Click the "Cancel" button** next to your job
3. **Confirm the cancellation** in the dialog
4. **Observe**:
   - The job should stop executing within 1-2 seconds
   - Check the Sidekiq logs - you should see: `"Job <jid> cancellation detected, interrupting..."`
   - The job should disappear from the Busy page

### Step 6: Verify Cancellation

Check the Sidekiq logs in the terminal where Sidekiq is running. You should see:

```
Job abc123def456 cancellation detected, interrupting...
Job abc123def456 was cancelled
```

### Testing Programmatically

You can also test cancellation programmatically:

```ruby
require 'sidekiq'
require 'sidekiq/api'

# Find a running job
workset = Sidekiq::WorkSet.new
work = workset.find_work("your-job-jid")

if work
  # Cancel it
  work.cancel!
  puts "Job cancelled!"
else
  puts "Job not found or not running"
end

# Or cancel directly by JID
workset.cancel_job("your-job-jid")
```

## Testing Edge Cases

### Test 1: Cancel Non-Existent Job

```ruby
workset = Sidekiq::WorkSet.new
result = workset.cancel_job("nonexistent-jid")
# Should return false
```

### Test 2: Cancel Already Completed Job

1. Enqueue a very short job (1 second)
2. Wait for it to complete
3. Try to cancel it - should return false or 404

### Test 3: Multiple Cancellation Attempts

1. Start a long-running job
2. Cancel it multiple times
3. Verify it only gets cancelled once

## Troubleshooting

### Job Not Appearing in Busy Page

- Make sure the job is actually running (not just enqueued)
- Check that Sidekiq is processing jobs (check logs)
- Refresh the Busy page

### Cancellation Not Working

- Check Sidekiq logs for errors
- Verify the middleware is loaded (check startup logs)
- Ensure Redis is accessible
- Check that the cancellation flag is being set:
  ```ruby
  Sidekiq.redis { |conn| conn.exists?("cancelled:your-jid") }
  ```

### Web UI Not Loading

- Make sure you have Rack session middleware configured
- Check that CSRF protection is disabled for testing or properly configured
- Verify the route is accessible

## Integration with Rails

If testing with a Rails app:

1. Add to `config/routes.rb`:
   ```ruby
   require 'sidekiq/web'
   mount Sidekiq::Web => '/sidekiq'
   ```

2. Create a test job in `app/jobs/`:
   ```ruby
   class TestCancellationJob < ApplicationJob
     def perform(duration = 10)
       duration.times { sleep 1 }
     end
   end
   ```

3. Enqueue and test:
   ```ruby
   TestCancellationJob.perform_later(30)
   ```

4. Visit `http://localhost:3000/sidekiq/busy` and cancel the job

## Performance Testing

To test cancellation performance:

```ruby
# Enqueue many jobs
100.times { LongRunningJob.perform_async(60) }

# Cancel them all quickly
workset = Sidekiq::WorkSet.new
workset.each do |process, thread, work|
  work.cancel!
end
```

Monitor:
- Redis memory usage
- Sidekiq CPU usage
- Cancellation response time

