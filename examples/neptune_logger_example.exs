# NeptuneLogger Example
#
# Demonstrates integration with Neptune.ai for experiment tracking.
#
# Prerequisites:
#   1. Create a Neptune account at https://neptune.ai
#   2. Create a project in the Neptune UI
#   3. Get your API token from User menu > Get your API token
#   4. Set environment variables:
#      export NEPTUNE_API_TOKEN="your-api-token"
#      export NEPTUNE_PROJECT="workspace/project-name"
#
# Rate Limiting:
#   Rate limiting is ENABLED by default with conservative settings:
#   - 200ms minimum interval between requests
#   - Automatic retry with exponential backoff on 429 errors
#
#   To customize: rate_limit: [min_interval_ms: 500, max_retries: 5]
#   To disable:   rate_limit: false
#
# Run with: mix run --no-start examples/neptune_logger_example.exs

# Start required applications for HTTP client
Application.ensure_all_started(:telemetry)
Application.ensure_all_started(:req)

alias CrucibleTrain.Logging

IO.puts("=== Neptune.ai Logger Demo ===\n")

# Check for required configuration
api_token = System.get_env("NEPTUNE_API_TOKEN")
project = System.get_env("NEPTUNE_PROJECT")

cond do
  is_nil(api_token) or api_token == "" ->
    IO.puts("""
    NEPTUNE_API_TOKEN environment variable not set.

    To use this example:
      1. Sign up at https://neptune.ai
      2. Create a project in the Neptune UI
      3. Get your API token from User menu > Get your API token
      4. Run:
         export NEPTUNE_API_TOKEN="your-api-token"
         export NEPTUNE_PROJECT="workspace/project-name"
      5. Re-run this example

    Exiting...
    """)

    System.halt(0)

  is_nil(project) or project == "" ->
    IO.puts("""
    NEPTUNE_PROJECT environment variable not set.

    The project should be in "workspace/project-name" format.
    Example: export NEPTUNE_PROJECT="my-team/ml-experiments"

    Exiting...
    """)

    System.halt(0)

  true ->
    :ok
end

run_name = "example-run-#{System.unique_integer([:positive])}"

IO.puts("Project: #{project}")
IO.puts("Run name: #{run_name}")
IO.puts("")

# Initialize Neptune logger
case Logging.create_logger(:neptune,
       api_token: api_token,
       project: project,
       run_name: run_name
     ) do
  {:ok, logger} ->
    # Get the run URL
    url = Logging.get_url(logger)
    IO.puts("Run URL: #{url}\n")

    # Log hyperparameters
    hparams = %{
      model: "deepseek-v3-7b",
      learning_rate: 2.0e-5,
      batch_size: 64,
      optimizer: %{
        name: "adam",
        eps: 1.0e-8
      },
      scheduler: "linear",
      max_steps: 1000
    }

    :ok = Logging.log_hparams(logger, hparams)
    IO.puts("Logged hyperparameters")

    # Simulate training loop
    IO.puts("\nSimulating training...")
    total_steps = 20

    for step <- 0..total_steps do
      progress = step / total_steps

      metrics = %{
        loss: 3.0 * :math.exp(-progress * 2.5) + 0.15,
        accuracy: 0.35 + progress * 0.55,
        learning_rate: 2.0e-5 * (1.0 - progress),
        gradient_norm: 1.2 + :rand.uniform() * 0.3,
        memory_mb: 8000 + :rand.uniform(500)
      }

      :ok = Logging.log_metrics(logger, step, metrics)

      if rem(step, 10) == 0 do
        IO.puts("  Step #{step}/#{total_steps}: loss=#{Float.round(metrics.loss, 4)}")
      end
    end

    # Log evaluation text
    :ok =
      Logging.log_long_text(logger, "eval_notes", """
      Evaluation Results:
      - Test accuracy: 0.89
      - Test loss: 0.35
      - Samples evaluated: 1000
      """)

    # Close the logger
    :ok = Logging.close(logger)
    IO.puts("\nRun completed and synced to Neptune!")
    IO.puts("View at: #{url}")

  {:error, reason} ->
    IO.puts("Failed to initialize Neptune logger: #{inspect(reason)}")
    IO.puts("\nCommon issues:")
    IO.puts("  - Invalid API token")
    IO.puts("  - Project doesn't exist")
    IO.puts("  - Project name format should be 'workspace/project'")
    System.halt(1)
end
