Sidekiq Cancelable
==================

[![Gem Version](https://badge.fury.io/rb/sidekiq-cancelable.svg)](https://rubygems.org/gems/sidekiq-cancelable)

A fork of [Sidekiq](https://github.com/sidekiq/sidekiq) with the ability to cancel running jobs directly from the Web UI.

## Features

This fork includes all the features of Sidekiq plus:

- **Cancel Running Jobs**: Cancel any running job directly from the `/sidekiq` Web UI Busy page
- **Graceful Cancellation**: Jobs are interrupted gracefully using thread-safe mechanisms
- **Real-time Monitoring**: Cancellation flags are checked every second during job execution

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-cancelable', git: 'https://github.com/afshmini/sidekiq-cancelable.git'
```

Or install it yourself as:

```bash
gem install sidekiq-cancelable
```

## Usage

### Canceling Running Jobs

1. Navigate to the Sidekiq Web UI at `/sidekiq`
2. Click on the **Busy** tab
3. Find the running job you want to cancel
4. Click the **Cancel** button next to the job
5. Confirm the cancellation

The job will be interrupted within 1 second of cancellation.

### Programmatic Cancellation

You can also cancel jobs programmatically:

```ruby
# Cancel a specific job by JID
workset = Sidekiq::WorkSet.new
workset.cancel_job("abc123def456")

# Or cancel via a Work object
work = workset.find_work("abc123def456")
work.cancel! if work
```

## How It Works

1. When you click "Cancel" in the Web UI, a cancellation flag is set in Redis with key `cancelled:<jid>`
2. A middleware monitors running jobs and checks for cancellation flags every second
3. When a cancellation is detected, the middleware raises a `Sidekiq::JobCancelled` exception
4. The Processor catches this exception and stops job execution without acknowledging the job
5. The cancellation flag is automatically cleaned up after the job stops

## Requirements

- Redis: Redis 7.0+, Valkey 7.2+ or Dragonfly 1.27+
- Ruby: MRI 3.2+ or JRuby 9.4+
- Rails and Active Job 7.0+ (if using Rails)

## Original Sidekiq

This is a fork of [Sidekiq](https://github.com/sidekiq/sidekiq), a simple, efficient background job processing library for Ruby.

Sidekiq uses threads to handle many jobs at the same time in the same process. Sidekiq can be used by any Ruby application.

## License

See [LICENSE.txt](LICENSE.txt) for licensing details.

## Author

**Afshmini** - [afshmini@gmail.com](mailto:afshmini@gmail.com)

Original Sidekiq by Mike Perham - [https://www.mikeperham.com](https://www.mikeperham.com)

## Repository

- **GitHub**: [https://github.com/afshmini/sidekiq-cancelable](https://github.com/afshmini/sidekiq-cancelable)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
