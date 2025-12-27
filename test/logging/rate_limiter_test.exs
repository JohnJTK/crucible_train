defmodule CrucibleTrain.Logging.RateLimiterTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Logging.RateLimiter

  describe "new/1" do
    test "creates rate limiter with default options" do
      limiter = RateLimiter.new()

      assert limiter.max_tokens == 10
      assert limiter.refill_rate == 2.0
      assert limiter.tokens == 10
      assert limiter.backoff_until == nil
    end

    test "creates rate limiter with custom options" do
      limiter = RateLimiter.new(max_tokens: 5, refill_rate: 1.0)

      assert limiter.max_tokens == 5
      assert limiter.refill_rate == 1.0
      assert limiter.tokens == 5
    end
  end

  describe "acquire/2" do
    test "allows request when tokens available" do
      limiter = RateLimiter.new(max_tokens: 10)

      assert {:ok, updated} = RateLimiter.acquire(limiter)
      assert updated.tokens == 9
    end

    test "allows request with custom cost" do
      limiter = RateLimiter.new(max_tokens: 10)

      assert {:ok, updated} = RateLimiter.acquire(limiter, 3)
      assert updated.tokens == 7
    end

    test "returns wait time when no tokens available" do
      limiter = RateLimiter.new(max_tokens: 10, refill_rate: 2.0)
      limiter = %{limiter | tokens: 0.0}

      assert {:wait, wait_ms, _updated} = RateLimiter.acquire(limiter)
      # Need 1 token at 2 tokens/sec = 500ms
      assert wait_ms == 500
    end

    test "returns wait time for partial token deficit" do
      limiter = RateLimiter.new(max_tokens: 10, refill_rate: 2.0)
      limiter = %{limiter | tokens: 1.0}

      # Request 3 tokens, only have 1, need 2 more at 2/sec = 1000ms
      assert {:wait, wait_ms, _updated} = RateLimiter.acquire(limiter, 3)
      assert wait_ms == 1000
    end

    test "respects backoff_until" do
      now = System.monotonic_time(:millisecond)
      backoff_until = now + 2000

      limiter = RateLimiter.new(max_tokens: 10)
      limiter = %{limiter | backoff_until: backoff_until}

      assert {:wait, wait_ms, returned} = RateLimiter.acquire(limiter)
      # Should wait approximately 2000ms (allowing some timing slack)
      assert wait_ms >= 1900 and wait_ms <= 2100
      # Limiter should be unchanged when in backoff
      assert returned.backoff_until == backoff_until
    end
  end

  describe "refill/1" do
    test "refills tokens based on elapsed time" do
      limiter = RateLimiter.new(max_tokens: 10, refill_rate: 2.0)
      limiter = %{limiter | tokens: 5}

      # Simulate 1 second passing
      old_time = System.monotonic_time(:millisecond) - 1000
      limiter = %{limiter | last_refill: old_time}

      refilled = RateLimiter.refill(limiter)

      # Should have gained ~2 tokens (2.0 tokens/sec * 1 sec)
      assert refilled.tokens >= 6.9 and refilled.tokens <= 7.1
    end

    test "caps tokens at max" do
      limiter = RateLimiter.new(max_tokens: 10, refill_rate: 100.0)
      limiter = %{limiter | tokens: 9}

      old_time = System.monotonic_time(:millisecond) - 1000
      limiter = %{limiter | last_refill: old_time}

      refilled = RateLimiter.refill(limiter)

      assert refilled.tokens == 10
    end
  end

  describe "on_rate_limited/2" do
    test "sets backoff_until from retry_after header" do
      limiter = RateLimiter.new()

      updated = RateLimiter.on_rate_limited(limiter, 5)

      now = System.monotonic_time(:millisecond)
      # Should be ~5 seconds in the future
      assert updated.backoff_until >= now + 4900
      assert updated.backoff_until <= now + 5100
    end

    test "uses exponential backoff when no retry_after" do
      limiter = RateLimiter.new()

      updated = RateLimiter.on_rate_limited(limiter, nil)

      now = System.monotonic_time(:millisecond)
      # Default backoff starts at 1 second
      assert updated.backoff_until >= now + 900
      assert updated.backoff_until <= now + 1100
      assert updated.consecutive_failures == 1
    end

    test "increases backoff exponentially on consecutive failures" do
      limiter = RateLimiter.new()
      limiter = %{limiter | consecutive_failures: 2}

      updated = RateLimiter.on_rate_limited(limiter, nil)

      now = System.monotonic_time(:millisecond)
      # 1000 * 2^2 = 4000ms
      assert updated.backoff_until >= now + 3900
      assert updated.backoff_until <= now + 4100
      assert updated.consecutive_failures == 3
    end

    test "caps exponential backoff at max" do
      limiter = RateLimiter.new(max_backoff_ms: 10_000)
      limiter = %{limiter | consecutive_failures: 10}

      updated = RateLimiter.on_rate_limited(limiter, nil)

      now = System.monotonic_time(:millisecond)
      # Should cap at 10 seconds
      assert updated.backoff_until >= now + 9900
      assert updated.backoff_until <= now + 10_100
    end
  end

  describe "on_success/1" do
    test "clears backoff and resets failures" do
      now = System.monotonic_time(:millisecond)
      limiter = RateLimiter.new()
      limiter = %{limiter | backoff_until: now + 5000, consecutive_failures: 3}

      updated = RateLimiter.on_success(limiter)

      assert updated.backoff_until == nil
      assert updated.consecutive_failures == 0
    end
  end

  describe "integration" do
    test "full flow: acquire, rate limit, backoff, success" do
      limiter = RateLimiter.new(max_tokens: 2, refill_rate: 1.0)

      # Use up tokens
      {:ok, limiter} = RateLimiter.acquire(limiter)
      {:ok, limiter} = RateLimiter.acquire(limiter)
      assert limiter.tokens == 0

      # Next acquire should wait
      {:wait, _wait_ms, limiter} = RateLimiter.acquire(limiter)

      # Simulate rate limit response
      limiter = RateLimiter.on_rate_limited(limiter, 1)
      assert is_integer(limiter.backoff_until)

      # Simulate success after waiting
      limiter = RateLimiter.on_success(limiter)
      assert limiter.backoff_until == nil
      assert limiter.consecutive_failures == 0
    end
  end
end
