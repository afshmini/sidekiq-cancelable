# frozen_string_literal: true

module Sidekiq
  module Middleware
    module Server
      class JobCancellation
        include Sidekiq::ServerMiddleware

        # Check interval in seconds for cancellation flag
        CHECK_INTERVAL = 1.0

        def call(instance, hash, queue)
          jid = hash["jid"]
          return yield unless jid

          # Check for cancellation before starting
          if cancelled?(jid)
            logger.info { "Job #{jid} was cancelled before execution" }
            raise Sidekiq::JobCancelled
          end

          # Start a background thread to monitor for cancellation
          cancellation_thread = nil
          job_thread = Thread.current

          begin
            cancellation_thread = Thread.new do
              Thread.current.name = "sidekiq-cancellation-#{jid}"
              loop do
                sleep CHECK_INTERVAL
                if cancelled?(jid)
                  logger.info { "Job #{jid} cancellation detected, interrupting..." }
                  # Use Thread.raise to interrupt the job thread
                  job_thread.raise Sidekiq::JobCancelled
                  break
                end
                # Stop monitoring if the job thread is dead
                break unless job_thread.alive?
              end
            end

            yield
          ensure
            # Clean up cancellation flag and monitoring thread
            cancellation_thread&.kill
            clear_cancellation_flag(jid)
          end
        end

        private

        def cancelled?(jid)
          key = "cancelled:#{jid}"
          redis do |conn|
            conn.exists?(key)
          end
        end

        def clear_cancellation_flag(jid)
          key = "cancelled:#{jid}"
          redis do |conn|
            conn.del(key)
          end
        end
      end
    end
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::JobCancellation
  end
end

