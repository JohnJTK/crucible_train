defmodule CrucibleTrain.Logging.RateLimiter do
  @moduledoc """
  Token bucket rate limiter with exponential backoff for HTTP API calls.

  Designed for use with cloud logging services (W&B, Neptune) that enforce
  rate limits on API requests.

  ## Algorithm

  Uses a token bucket algorithm:
  - Tokens are consumed when making requests
  - Tokens refill at a constant rate over time
  - When bucket is empty, callers must wait

  When a 429 (rate limited) response is received:
  - Uses `Retry-After` header if provided
  - Falls back to exponential backoff (1s, 2s, 4s, 8s... up to max)

  ## Example

      limiter = RateLimiter.new(max_tokens: 10, refill_rate: 2.0)

      case RateLimiter.acquire(limiter) do
        {:ok, limiter} ->
          # Make request
          case make_request() do
            {:ok, _} -> RateLimiter.on_success(limiter)
            {:error, :rate_limited, retry_after} ->
              RateLimiter.on_rate_limited(limiter, retry_after)
          end

        {:wait, ms, limiter} ->
          Process.sleep(ms)
          # Retry acquire
      end

  ## Configuration

  - `:max_tokens` - Maximum bucket capacity (default: 10)
  - `:refill_rate` - Tokens added per second (default: 2.0)
  - `:max_backoff_ms` - Maximum backoff time in ms (default: 30_000)
  """

  defstruct [
    :max_tokens,
    :refill_rate,
    :tokens,
    :last_refill,
    :backoff_until,
    :consecutive_failures,
    :max_backoff_ms
  ]

  @type t :: %__MODULE__{
          max_tokens: pos_integer(),
          refill_rate: float(),
          tokens: float(),
          last_refill: integer(),
          backoff_until: integer() | nil,
          consecutive_failures: non_neg_integer(),
          max_backoff_ms: pos_integer()
        }

  @default_max_tokens 10
  @default_refill_rate 2.0
  @default_max_backoff_ms 30_000
  @base_backoff_ms 1_000

  @doc """
  Creates a new rate limiter with the given options.

  ## Options

  - `:max_tokens` - Maximum bucket capacity (default: 10)
  - `:refill_rate` - Tokens per second (default: 2.0)
  - `:max_backoff_ms` - Maximum backoff time (default: 30_000)
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    max_tokens = Keyword.get(opts, :max_tokens, @default_max_tokens)
    refill_rate = Keyword.get(opts, :refill_rate, @default_refill_rate)
    max_backoff_ms = Keyword.get(opts, :max_backoff_ms, @default_max_backoff_ms)

    %__MODULE__{
      max_tokens: max_tokens,
      refill_rate: refill_rate,
      tokens: max_tokens * 1.0,
      last_refill: System.monotonic_time(:millisecond),
      backoff_until: nil,
      consecutive_failures: 0,
      max_backoff_ms: max_backoff_ms
    }
  end

  @doc """
  Attempts to acquire tokens for a request.

  Returns:
  - `{:ok, updated_limiter}` - Request can proceed
  - `{:wait, milliseconds, limiter}` - Must wait before requesting
  """
  @spec acquire(t(), pos_integer()) :: {:ok, t()} | {:wait, pos_integer(), t()}
  def acquire(limiter, cost \\ 1) do
    now = System.monotonic_time(:millisecond)

    # Check if we're in backoff
    case limiter.backoff_until do
      nil ->
        acquire_tokens(limiter, cost, now)

      backoff_until when backoff_until > now ->
        wait_ms = backoff_until - now
        {:wait, wait_ms, limiter}

      _expired ->
        # Backoff expired, clear it and try to acquire
        limiter = %{limiter | backoff_until: nil}
        acquire_tokens(limiter, cost, now)
    end
  end

  defp acquire_tokens(limiter, cost, now) do
    limiter = refill_at(limiter, now)

    if limiter.tokens >= cost do
      {:ok, %{limiter | tokens: limiter.tokens - cost}}
    else
      # Calculate wait time based on token deficit
      deficit = cost - limiter.tokens
      wait_ms = ceil(deficit / limiter.refill_rate * 1000)
      {:wait, wait_ms, limiter}
    end
  end

  @doc """
  Refills tokens based on elapsed time since last refill.
  """
  @spec refill(t()) :: t()
  def refill(limiter) do
    refill_at(limiter, System.monotonic_time(:millisecond))
  end

  defp refill_at(limiter, now) do
    elapsed_ms = now - limiter.last_refill
    elapsed_sec = elapsed_ms / 1000.0
    new_tokens = limiter.tokens + elapsed_sec * limiter.refill_rate
    capped_tokens = min(new_tokens, limiter.max_tokens * 1.0)

    %{limiter | tokens: capped_tokens, last_refill: now}
  end

  @doc """
  Called when a rate limit (429) response is received.

  Uses the retry_after value if provided (in seconds), otherwise
  falls back to exponential backoff.
  """
  @spec on_rate_limited(t(), integer() | nil) :: t()
  def on_rate_limited(limiter, retry_after_seconds) do
    now = System.monotonic_time(:millisecond)
    consecutive = limiter.consecutive_failures + 1

    backoff_ms =
      if retry_after_seconds do
        retry_after_seconds * 1000
      else
        # Exponential backoff: 1s, 2s, 4s, 8s...
        backoff = @base_backoff_ms * :math.pow(2, limiter.consecutive_failures)
        min(round(backoff), limiter.max_backoff_ms)
      end

    %{limiter | backoff_until: now + backoff_ms, consecutive_failures: consecutive}
  end

  @doc """
  Called when a request succeeds. Clears backoff state.
  """
  @spec on_success(t()) :: t()
  def on_success(limiter) do
    %{limiter | backoff_until: nil, consecutive_failures: 0}
  end
end
