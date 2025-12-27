# Scoring Example
#
# Demonstrates the pluggable scoring system for evaluation.
# Includes exact match, contains, and semantic similarity scoring.
#
# Run with: mix run examples/scoring_example.exs

alias CrucibleTrain.Eval.Scoring

IO.puts("=== Scoring Functions Demo ===\n")

# Test cases
test_cases = [
  {"Paris", "Paris"},
  {"The capital of France is Paris", "Paris"},
  {"PARIS", "paris"},
  {"The answer is 42", "42"},
  {"Machine learning is a subset of AI", "machine learning"},
  {"Hello world!", "Goodbye world!"}
]

# --- Exact Match Scoring ---
IO.puts("## Exact Match Scoring")
IO.puts("Scores 1.0 if output exactly matches target (after trimming), 0.0 otherwise.\n")

for {output, target} <- test_cases do
  score = Scoring.score(:exact_match, output, target)
  IO.puts("  Output: #{inspect(output)}")
  IO.puts("  Target: #{inspect(target)}")
  IO.puts("  Score:  #{score}\n")
end

# --- Contains Scoring ---
IO.puts("\n## Contains Scoring")
IO.puts("Scores 1.0 if output contains target as a substring, 0.0 otherwise.\n")

for {output, target} <- test_cases do
  score = Scoring.score(:contains, output, target)
  IO.puts("  Output: #{inspect(output)}")
  IO.puts("  Target: #{inspect(target)}")
  IO.puts("  Score:  #{score}\n")
end

# --- Semantic Similarity Scoring ---
IO.puts("\n## Semantic Similarity Scoring")
IO.puts("Uses embeddings to compute cosine similarity. Requires an embedding client.\n")

# Note: Semantic similarity requires a configured embedding client
# This example shows the interface - actual usage requires ports configuration
IO.puts("""
  Semantic similarity scoring requires an embedding client to be configured.

  Example usage with a configured ports map:

    score = Scoring.score(:semantic_similarity, output, target,
      ports: %{embedding_client: my_embedding_client},
      embedding_opts: [model: "text-embedding-3-small"]
    )

  The score will be a float between 0.0 and 1.0 representing cosine similarity.
""")

# --- Custom Scorer ---
IO.puts("\n## Custom Scorer")
IO.puts("You can implement the Scoring behaviour for custom scoring logic.\n")

# Define a simple custom scorer inline
defmodule LevenshteinScorer do
  @behaviour CrucibleTrain.Eval.Scoring

  @impl true
  def score(output, target, _opts) do
    # Normalized Levenshtein similarity
    distance = levenshtein(String.downcase(output), String.downcase(target))
    max_len = max(String.length(output), String.length(target))
    if max_len == 0, do: 1.0, else: 1.0 - distance / max_len
  end

  @impl true
  def name, do: "levenshtein"

  defp levenshtein(s1, s2) do
    # Simple Levenshtein implementation
    if s1 == s2 do
      0
    else
      levenshtein_impl(String.graphemes(s1), String.graphemes(s2))
    end
  end

  defp levenshtein_impl([], t), do: length(t)
  defp levenshtein_impl(s, []), do: length(s)

  defp levenshtein_impl([h1 | t1] = s, [h2 | t2] = t) do
    if h1 == h2 do
      levenshtein_impl(t1, t2)
    else
      1 +
        Enum.min([
          # insert
          levenshtein_impl(s, t2),
          # delete
          levenshtein_impl(t1, t),
          # replace
          levenshtein_impl(t1, t2)
        ])
    end
  end
end

# Use custom scorer
for {output, target} <- Enum.take(test_cases, 3) do
  score = Scoring.score(LevenshteinScorer, output, target)
  IO.puts("  Output: #{inspect(output)}")
  IO.puts("  Target: #{inspect(target)}")
  IO.puts("  Score:  #{Float.round(score, 4)}\n")
end

IO.puts("\nDone!")
