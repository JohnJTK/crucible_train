# MultiplexLogger Example
#
# Demonstrates logging to multiple backends simultaneously.
# Useful for logging locally while also sending to cloud services.
#
# Run with: mix run examples/multiplex_logger_example.exs

alias CrucibleTrain.Logging
alias CrucibleTrain.Logging.{JsonLogger, PrettyPrintLogger}

IO.puts("=== Multiplex Logger Demo ===\n")

# Create a temporary log directory
log_dir =
  Path.join(System.tmp_dir!(), "crucible_train_multiplex_#{System.unique_integer([:positive])}")

IO.puts("JSON logs will be written to: #{log_dir}\n")

# Initialize multiplex logger with multiple backends
# Each backend receives the same log calls
logger_specs = [
  {JsonLogger, [log_dir: log_dir]},
  {PrettyPrintLogger, []}
]

{:ok, logger} = Logging.create_logger(:multiplex, loggers: logger_specs)

# Log hyperparameters (goes to both backends)
hparams = %{
  model: "qwen3-7b",
  learning_rate: 5.0e-5,
  batch_size: 16,
  gradient_accumulation: 4
}

:ok = Logging.log_hparams(logger, hparams)

IO.puts("")

# Log metrics (goes to both backends)
for step <- [0, 50, 100] do
  metrics = %{
    train_loss: 2.0 - step * 0.015,
    eval_loss: 2.1 - step * 0.012,
    grad_norm: 1.5 + :rand.uniform() * 0.5
  }

  :ok = Logging.log_metrics(logger, step, metrics)
  IO.puts("")
end

# Close all backends
:ok = Logging.close(logger)

IO.puts("All loggers closed.")
IO.puts("\nJSON files created in: #{log_dir}")

Path.wildcard(Path.join(log_dir, "*"))
|> Enum.each(fn path -> IO.puts("  - #{Path.basename(path)}") end)
