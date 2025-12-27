defmodule CrucibleTrain.Eval.BatchRunner do
  @moduledoc """
  Streaming batch evaluation runner.
  """

  require Logger

  alias CrucibleTrain.Eval.{Runner, Scoring}
  alias CrucibleTrain.Logging.DumpConfig

  @doc """
  Stream evaluation in chunks.
  """
  @spec stream_evaluate([map()], map(), keyword()) :: Enumerable.t()
  def stream_evaluate(samples, config, opts \\ []) do
    chunk_size = Keyword.get(opts, :chunk_size, 25)
    score_method = Keyword.get(opts, :score_method, :exact_match)
    score_opts = Keyword.get(opts, :score_opts, [])

    samples
    |> Stream.chunk_every(chunk_size)
    |> Stream.flat_map(&evaluate_chunk(&1, config, score_method, score_opts))
  end

  @doc """
  Persist results to JSONL file.
  """
  @spec persist_results(Enumerable.t(), Path.t()) :: :ok | {:error, term()}
  def persist_results(results, path) do
    File.mkdir_p!(Path.dirname(path))

    Enum.reduce_while(results, :ok, fn result, :ok ->
      json = Jason.encode!(DumpConfig.dump(result))

      case File.write(path, json <> "\n", [:append]) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  @doc """
  Aggregate metrics from results.
  """
  @spec aggregate_metrics([map()]) :: map()
  def aggregate_metrics(results) do
    total = length(results)
    scores = Enum.map(results, &Map.get(&1, :score, 0.0))

    if total == 0 do
      %{mean_score: 0.0, total: 0, correct: 0}
    else
      mean_score = Enum.sum(scores) / total
      correct = Enum.count(scores, &(&1 == 1.0))
      %{mean_score: mean_score, total: total, correct: correct}
    end
  end

  defp evaluate_chunk(chunk, config, score_method, score_opts) do
    case Runner.run(chunk, config) do
      {:ok, results} ->
        Enum.map(results, &score_result(&1, score_method, score_opts))

      {:error, reason} ->
        Logger.warning("Batch evaluation failed: #{inspect(reason)}")
        []
    end
  end

  defp score_result(result, score_method, score_opts) do
    score = Scoring.score(score_method, result.output, result.target, score_opts)
    Map.put(result, :score, score)
  end
end
