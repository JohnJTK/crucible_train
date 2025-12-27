defmodule CrucibleTrain.Eval.Scorers.SemanticSimilarity do
  @moduledoc """
  Semantic similarity scorer using embeddings.
  """

  @behaviour CrucibleTrain.Eval.Scoring

  alias CrucibleTrain.Ports.EmbeddingClient

  @impl true
  def score(output, target, opts) do
    ports = Keyword.fetch!(opts, :ports)
    embed_opts = Keyword.get(opts, :embedding_opts, [])

    with {:ok, [output_emb]} <- EmbeddingClient.embed_texts(ports, [output], embed_opts),
         {:ok, [target_emb]} <- EmbeddingClient.embed_texts(ports, [target], embed_opts) do
      cosine_similarity(output_emb, target_emb)
    else
      {:error, _reason} -> 0.0
      _ -> 0.0
    end
  end

  @impl true
  def name, do: "semantic_similarity"

  defp cosine_similarity(a, b) when is_list(a) and is_list(b) do
    count_a = Enum.count(a)
    count_b = Enum.count(b)

    if count_a == count_b and count_a > 0 do
      dot = Enum.zip(a, b) |> Enum.reduce(0.0, fn {x, y}, acc -> acc + x * y end)
      norm_a = :math.sqrt(Enum.reduce(a, 0.0, fn x, acc -> acc + x * x end))
      norm_b = :math.sqrt(Enum.reduce(b, 0.0, fn x, acc -> acc + x * x end))

      if norm_a == 0.0 or norm_b == 0.0 do
        0.0
      else
        dot / (norm_a * norm_b)
      end
    else
      0.0
    end
  end

  defp cosine_similarity(_a, _b), do: 0.0
end
