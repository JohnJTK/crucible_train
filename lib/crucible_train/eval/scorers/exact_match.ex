defmodule CrucibleTrain.Eval.Scorers.ExactMatch do
  @moduledoc """
  Exact string match scorer.
  """

  @behaviour CrucibleTrain.Eval.Scoring

  @impl true
  def score(output, target, _opts) do
    if String.trim(output) == String.trim(target), do: 1.0, else: 0.0
  end

  @impl true
  def name, do: "exact_match"
end
