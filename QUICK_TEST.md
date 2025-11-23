# Quick Testing Guide

## Fastest Way to Test

### 1. Start Redis (if not running)
```bash
redis-server
# or if using Docker:
docker run -d -p 6379:6379 redis:7
```

### 2. Start Sidekiq in Terminal 1
```bash
bundle exec sidekiq
```

### 3. Start Web UI in Terminal 2
```bash
ruby test_web_ui.rb
```

### 4. Enqueue a Test Job in Terminal 3
```bash
ruby test_manual.rb
```

This will:
- Enqueue a 30-second job
- Show you the JID
- Give you instructions

### 5. Test Cancellation

1. Open browser: http://localhost:4567/sidekiq/busy
2. Find your running job in the "Jobs" table
3. Click the **Cancel** button
4. Confirm the cancellation
5. Watch the job stop within 1-2 seconds
6. Check Terminal 1 (Sidekiq logs) for cancellation messages

## What to Look For

### In Sidekiq Logs (Terminal 1):
```
Job abc123 cancellation detected, interrupting...
Job abc123 was cancelled
```

### In Browser:
- Job disappears from Busy page
- No error messages

### In Redis (optional check):
```ruby
# In IRB
require 'sidekiq'
Sidekiq.redis { |conn| conn.keys("cancelled:*") }
# Should show cancellation flags (they auto-expire after 1 hour)
```

## Troubleshooting

**Job not showing in Busy page?**
- Make sure Sidekiq is actually processing jobs
- Check that the job started (not just enqueued)
- Refresh the page

**Cancel button not working?**
- Check browser console for errors
- Verify CSRF is disabled (for testing) or properly configured
- Check Sidekiq logs for errors

**Job doesn't stop?**
- Check Sidekiq logs for middleware errors
- Verify the cancellation middleware is loaded (check startup logs)
- Make sure Redis is accessible

## Programmatic Test

You can also test programmatically:

```ruby
require 'sidekiq'
require 'sidekiq/api'

# Enqueue a job
class TestJob
  include Sidekiq::Job
  def perform; sleep 60; end
end

jid = TestJob.perform_async

# Wait a moment for it to start
sleep 2

# Cancel it
workset = Sidekiq::WorkSet.new
if workset.cancel_job(jid)
  puts "Job cancelled!"
else
  puts "Job not found or already finished"
end
```

