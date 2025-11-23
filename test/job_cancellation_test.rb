# frozen_string_literal: true

require_relative "helper"
require "sidekiq/api"

class LongRunningJob
  include Sidekiq::Job

  def perform(duration = 5)
    sleep duration
  end
end

describe "Job Cancellation" do
  before do
    @config = reset!
  end

  describe "WorkSet#cancel_job" do
    it "returns false for non-existent job" do
      workset = Sidekiq::WorkSet.new
      assert_equal false, workset.cancel_job("nonexistent-jid")
    end

    it "sets cancellation flag in Redis" do
      jid = "test-job-123"
      workset = Sidekiq::WorkSet.new
      
      # Set cancellation flag
      result = workset.cancel_job(jid)
      
      # Check that flag exists in Redis
      flag_exists = @config.redis { |conn| conn.exists?("cancelled:#{jid}") }
      assert flag_exists, "Cancellation flag should be set in Redis"
    end
  end

  describe "Work#cancel!" do
    it "sets cancellation flag for the job" do
      jid = "test-job-456"
      
      # Create a mock work object
      work = Sidekiq::Work.new("process-id", "thread-id", {
        "queue" => "default",
        "run_at" => Time.now.to_i,
        "payload" => Sidekiq.dump_json({"class" => "TestJob", "jid" => jid, "args" => []})
      })
      
      result = work.cancel!
      assert_equal true, result
      
      # Check that flag exists
      flag_exists = @config.redis { |conn| conn.exists?("cancelled:#{jid}") }
      assert flag_exists, "Cancellation flag should be set"
    end
  end

  describe "Web UI cancellation route" do
    include Rack::Test::Methods

    def app
      @app ||= Rack::Lint.new(Sidekiq::Web.new)
    end

    before do
      Sidekiq::Web.configure do |c|
        c.middlewares.clear
        c.use Rack::Session::Cookie, secrets: "35c5108120cb479eecb4e947e423cad6da6f38327cf0ebb323e30816d74fa01f"
      end
    end

    it "returns 400 when jid is missing" do
      post "/busy/cancel"
      assert_equal 400, last_response.status
    end

    it "returns 404 when job is not running" do
      post "/busy/cancel", "jid" => "nonexistent-jid"
      assert_equal 404, last_response.status
    end

    it "redirects when job is cancelled successfully" do
      # Create a running job by simulating work state
      jid = "running-job-123"
      process_id = "test-process"
      thread_id = "test-thread"
      
      # Simulate a running job by adding it to the work state
      @config.redis do |conn|
        conn.sadd("processes", process_id)
        conn.hset("#{process_id}:work", thread_id, Sidekiq.dump_json({
          "queue" => "default",
          "run_at" => Time.now.to_i,
          "payload" => Sidekiq.dump_json({
            "class" => "LongRunningJob",
            "jid" => jid,
            "args" => []
          })
        }))
        conn.hset(process_id, "busy", 1)
      end

      post "/busy/cancel", "jid" => jid
      assert_equal 302, last_response.status
      assert_match %r{/busy}, last_response.location
      
      # Verify cancellation flag was set
      flag_exists = @config.redis { |conn| conn.exists?("cancelled:#{jid}") }
      assert flag_exists, "Cancellation flag should be set"
    end
  end

  describe "JobCancelled exception" do
    it "is defined and inherits from Interrupt" do
      assert Sidekiq::JobCancelled < Interrupt
    end
  end
end

