defmodule CrucibleTrain.Eval.Scorers.SemanticSimilarityTest do
  use ExUnit.Case, async: true

  import Mox

  alias CrucibleTrain.Eval.Scorers.SemanticSimilarity
  alias CrucibleTrain.Ports

  setup :verify_on_exit!
  setup :set_mox_from_context

  defp ports_with_mock do
    Ports.new(ports: %{embedding_client: CrucibleTrain.Ports.EmbeddingClientMock})
  end

  test "computes cosine similarity from embeddings" do
    ports = ports_with_mock()

    expect(CrucibleTrain.Ports.EmbeddingClientMock, :embed_texts, fn _opts, ["out"], _opts2 ->
      {:ok, [[1.0, 0.0]]}
    end)

    expect(CrucibleTrain.Ports.EmbeddingClientMock, :embed_texts, fn _opts, ["target"], _opts2 ->
      {:ok, [[1.0, 0.0]]}
    end)

    assert_in_delta SemanticSimilarity.score("out", "target", ports: ports), 1.0, 1.0e-6
  end

  test "returns 0.0 when embeddings fail" do
    ports = ports_with_mock()

    expect(CrucibleTrain.Ports.EmbeddingClientMock, :embed_texts, fn _opts, ["out"], _opts2 ->
      {:error, :failed}
    end)

    assert SemanticSimilarity.score("out", "target", ports: ports) == 0.0
  end
end
