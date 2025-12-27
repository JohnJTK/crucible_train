# JsonLogger Example
#
# Demonstrates local JSONL logging for training metrics and hyperparameters.
# No external services required.
#
# Run with: mix run examples/json_logger_example.exs

alias CrucibleTrain.Logging

# Create a temporary log directory
log_dir =
  Path.join(System.tmp_dir!(), "crucible_train_demo_#{System.unique_integer([:positive])}")

IO.puts("Logging to: #{log_dir}")

# Initialize the JSON logger
{:ok, logger} = Logging.create_logger(:json, log_dir: log_dir)

# Log hyperparameters
hparams = %{
  model: "llama-3.1-8b",
  learning_rate: 1.0e-4,
  batch_size: 32,
  optimizer: %{name: "adamw", beta1: 0.9, beta2: 0.999}
}

:ok = Logging.log_hparams(logger, hparams)
IO.puts("Logged hyperparameters")

# Simulate training loop with metrics
for step <- 0..9 do
  metrics = %{
    loss: 2.5 - step * 0.2 + :rand.uniform() * 0.1,
    accuracy: 0.5 + step * 0.04,
    learning_rate: 1.0e-4 * (1.0 - step / 10)
  }

  :ok = Logging.log_metrics(logger, step, metrics)

  IO.puts(
    "Step #{step}: loss=#{Float.round(metrics.loss, 4)}, accuracy=#{Float.round(metrics.accuracy, 4)}"
  )
end

# Log long-form text (e.g., evaluation samples)
sample_output = """
Input: What is the capital of France?
Output: The capital of France is Paris.
Expected: Paris
Score: 1.0
"""

:ok = Logging.log_long_text(logger, "eval_sample_0", sample_output)

# Close the logger
:ok = Logging.close(logger)
IO.puts("\nLogger closed. Files created:")

# Show created files
Path.wildcard(Path.join(log_dir, "*"))
|> Enum.each(fn path ->
  IO.puts("  - #{Path.basename(path)}")
end)

# Display sample content
metrics_file = Path.join(log_dir, "metrics.jsonl")
IO.puts("\nSample metrics.jsonl content (first 3 lines):")

metrics_file
|> File.stream!()
|> Enum.take(3)
|> Enum.each(&IO.write/1)
