# PrettyPrintLogger Example
#
# Demonstrates console table output for training metrics.
# Great for development and debugging.
#
# Run with: mix run examples/pretty_print_logger_example.exs

alias CrucibleTrain.Logging

IO.puts("=== PrettyPrint Logger Demo ===\n")

# Initialize the pretty print logger
{:ok, logger} = Logging.create_logger(:pretty)

# Log hyperparameters - displays as a formatted table
hparams = %{
  model: "llama-3.1-8b",
  learning_rate: 1.0e-4,
  batch_size: 32,
  num_epochs: 3,
  warmup_steps: 100
}

:ok = Logging.log_hparams(logger, hparams)

IO.puts("")

# Simulate training with metrics
for step <- [0, 100, 200, 300, 400, 500] do
  progress = step / 500

  metrics = %{
    loss: 2.5 * :math.exp(-progress * 2) + 0.3,
    accuracy: 0.5 + progress * 0.4,
    perplexity: :math.exp(2.5 * :math.exp(-progress * 2) + 0.3),
    tokens_per_sec: 50_000 + :rand.uniform(5000)
  }

  :ok = Logging.log_metrics(logger, step, metrics)
  IO.puts("")
end

# Log long text
:ok = Logging.log_long_text(logger, "summary", "Training completed successfully!")

:ok = Logging.close(logger)
IO.puts("Logger closed.")
