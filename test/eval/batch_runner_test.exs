defmodule CrucibleTrain.Eval.BatchRunnerTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Completers.MockCompleter
  alias CrucibleTrain.Eval.BatchRunner
  alias CrucibleTrain.Renderers.Types

  defp message_completer(output) do
    MockCompleter.new(message_fn: fn _messages -> {:ok, Types.message("assistant", output)} end)
  end

  test "stream_evaluate scores results in batches" do
    samples = [
      %{id: "1", input: "hi", target: "ok"},
      %{id: "2", input: "hi2", target: "no"}
    ]

    config = %{message_completer: message_completer("ok")}

    results =
      samples
      |> BatchRunner.stream_evaluate(config, chunk_size: 1, score_method: :exact_match)
      |> Enum.to_list()

    assert Enum.map(results, & &1.score) == [1.0, 0.0]
  end

  test "persist_results writes JSONL" do
    tmp_dir = Path.join(System.tmp_dir!(), "crucible_train_#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(tmp_dir) end)
    path = Path.join(tmp_dir, "results.jsonl")

    results = [
      %{id: "1", output: "ok", target: "ok", score: 1.0},
      %{id: "2", output: "no", target: "ok", score: 0.0}
    ]

    assert :ok = BatchRunner.persist_results(results, path)

    lines =
      path
      |> File.read!()
      |> String.split("\n", trim: true)

    assert length(lines) == 2

    assert Enum.all?(lines, fn line ->
             case Jason.decode(line) do
               {:ok, _} -> true
               _ -> false
             end
           end)
  end

  test "aggregate_metrics computes summary stats" do
    results = [%{score: 1.0}, %{score: 0.0}, %{score: 0.5}]

    assert BatchRunner.aggregate_metrics(results) == %{mean_score: 0.5, total: 3, correct: 1}
  end
end
