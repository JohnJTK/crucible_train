# WandbLogger Example
#
# Demonstrates integration with Weights & Biases for experiment tracking.
#
# Prerequisites:
#   1. Create a W&B account at https://wandb.ai
#   2. Get your API key from https://wandb.ai/authorize
#   3. Set the WANDB_API_KEY environment variable:
#      export WANDB_API_KEY="your-api-key"
#
# Rate Limiting:
#   W&B free tier has strict rate limits (~60 requests/minute per run).
#   Rate limiting is ENABLED by default with conservative settings:
#   - 500ms minimum interval between requests
#   - Automatic retry with exponential backoff on 429 errors
#
#   To customize: rate_limit: [min_interval_ms: 1000, max_retries: 5]
#   To disable:   rate_limit: false
#
# Run with: mix run --no-start examples/wandb_logger_example.exs

# Start required applications for HTTP client
Application.ensure_all_started(:telemetry)
Application.ensure_all_started(:req)

alias CrucibleTrain.Logging

IO.puts("=== Weights & Biases Logger Demo ===\n")

# Check for API key
api_key = System.get_env("WANDB_API_KEY")

if is_nil(api_key) or api_key == "" do
  IO.puts("""
  WANDB_API_KEY environment variable not set.

  To use this example:
    1. Sign up at https://wandb.ai
    2. Get your API key from https://wandb.ai/authorize
    3. Run: export WANDB_API_KEY="your-api-key"
    4. Re-run this example

  Exiting...
  """)

  System.halt(0)
end

# Configuration
project = System.get_env("WANDB_PROJECT", "crucible-train-demo")
# Optional: your team/username
entity = System.get_env("WANDB_ENTITY")
run_name = "example-run-#{System.unique_integer([:positive])}"

IO.puts("Project: #{project}")
IO.puts("Entity: #{entity || "(default)"}")
IO.puts("Run name: #{run_name}")
IO.puts("")

# Initialize W&B logger
case Logging.create_logger(:wandb,
       api_key: api_key,
       project: project,
       entity: entity,
       run_name: run_name
     ) do
  {:ok, logger} ->
    # Get the run URL
    url = Logging.get_url(logger)
    IO.puts("Run URL: #{url}\n")

    # Log hyperparameters
    hparams = %{
      model: "llama-3.1-8b",
      learning_rate: 1.0e-4,
      batch_size: 32,
      optimizer: %{
        name: "adamw",
        weight_decay: 0.01,
        betas: [0.9, 0.999]
      },
      scheduler: "cosine",
      warmup_steps: 100
    }

    :ok = Logging.log_hparams(logger, hparams)
    IO.puts("Logged hyperparameters")

    # Simulate training loop
    IO.puts("\nSimulating training...")
    total_steps = 20

    for step <- 0..total_steps do
      progress = step / total_steps

      metrics = %{
        train_loss: 2.5 * :math.exp(-progress * 3) + 0.2,
        train_accuracy: 0.4 + progress * 0.5,
        learning_rate: 1.0e-4 * (0.5 * (1 + :math.cos(:math.pi() * progress))),
        epoch: div(step, 10),
        tokens_per_second: 45_000 + :rand.uniform(10_000)
      }

      :ok = Logging.log_metrics(logger, step, metrics)

      if rem(step, 10) == 0 do
        IO.puts("  Step #{step}/#{total_steps}: loss=#{Float.round(metrics.train_loss, 4)}")
      end
    end

    # Log final summary
    :ok =
      Logging.log_long_text(logger, "training_summary", """
      Training completed successfully.
      Final loss: 0.42
      Final accuracy: 0.91
      Total steps: #{total_steps}
      """)

    # Close the logger (marks run as finished)
    :ok = Logging.close(logger)
    IO.puts("\nRun completed and synced to W&B!")
    IO.puts("View at: #{url}")

  {:error, reason} ->
    IO.puts("Failed to initialize W&B logger: #{inspect(reason)}")
    IO.puts("\nCommon issues:")
    IO.puts("  - Invalid API key")
    IO.puts("  - Network connectivity issues")
    IO.puts("  - Project doesn't exist (will be auto-created on first run)")
    System.halt(1)
end
