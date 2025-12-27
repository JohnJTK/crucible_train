# BatchRunner Example
#
# Demonstrates streaming batch evaluation with the BatchRunner.
# This example uses mock data since it requires a configured evaluator.
#
# Run with: mix run examples/batch_runner_example.exs

alias CrucibleTrain.Eval.BatchRunner

IO.puts("=== Batch Evaluation Runner Demo ===\n")

# In a real scenario, you would have:
# - A list of samples with inputs and expected outputs
# - An evaluation configuration with a model/client
# - The BatchRunner would stream through samples in chunks

IO.puts("## BatchRunner API Overview\n")

IO.puts("""
The BatchRunner provides streaming batch evaluation capabilities:

  # Stream evaluation in chunks
  samples = [
    %{input: "What is 2+2?", target: "4"},
    %{input: "Capital of France?", target: "Paris"},
    # ... more samples
  ]

  config = %{
    client: my_llm_client,
    model: "llama-3.1-8b"
  }

  results =
    samples
    |> BatchRunner.stream_evaluate(config, chunk_size: 25, score_method: :contains)
    |> Enum.to_list()

  # Persist results to JSONL
  :ok = BatchRunner.persist_results(results, "output/results.jsonl")

  # Aggregate metrics
  metrics = BatchRunner.aggregate_metrics(results)
  # => %{mean_score: 0.85, total: 100, correct: 85}
""")

# Demonstrate aggregate_metrics with mock results
IO.puts("\n## Aggregate Metrics Demo\n")

# Create mock evaluation results
mock_results = [
  %{input: "2+2", output: "4", target: "4", score: 1.0},
  %{input: "3+3", output: "6", target: "6", score: 1.0},
  %{input: "5+5", output: "11", target: "10", score: 0.0},
  %{input: "7+7", output: "14", target: "14", score: 1.0},
  %{input: "8+8", output: "15", target: "16", score: 0.0},
  %{input: "9+9", output: "18", target: "18", score: 1.0},
  %{input: "10+10", output: "20", target: "20", score: 1.0},
  %{input: "11+11", output: "22", target: "22", score: 1.0},
  %{input: "12+12", output: "25", target: "24", score: 0.0},
  %{input: "13+13", output: "26", target: "26", score: 1.0}
]

IO.puts("Mock results (#{length(mock_results)} samples):")

for result <- mock_results do
  status = if result.score == 1.0, do: "[OK]", else: "[X]"
  IO.puts("  #{status} #{result.input} => #{result.output} (expected: #{result.target})")
end

metrics = BatchRunner.aggregate_metrics(mock_results)
IO.puts("\nAggregate metrics:")
IO.puts("  Total samples:  #{metrics.total}")
IO.puts("  Correct:        #{metrics.correct}")
IO.puts("  Mean score:     #{Float.round(metrics.mean_score, 4)}")
IO.puts("  Accuracy:       #{Float.round(metrics.correct / metrics.total * 100, 1)}%")

# Demonstrate persist_results
IO.puts("\n## Persist Results Demo\n")

output_dir =
  Path.join(System.tmp_dir!(), "crucible_train_batch_#{System.unique_integer([:positive])}")

output_file = Path.join(output_dir, "results.jsonl")

:ok = BatchRunner.persist_results(mock_results, output_file)
IO.puts("Results persisted to: #{output_file}")

IO.puts("\nSample output (first 3 lines):")

output_file
|> File.stream!()
|> Enum.take(3)
|> Enum.each(fn line ->
  # Pretty print the JSON
  decoded = Jason.decode!(line)
  IO.puts("  #{Jason.encode!(decoded)}")
end)

IO.puts("\nDone!")
