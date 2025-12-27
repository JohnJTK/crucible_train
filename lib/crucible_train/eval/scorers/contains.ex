defmodule CrucibleTrain.Eval.Scorers.Contains do
  @moduledoc """
  Substring containment scorer.
  """

  @behaviour CrucibleTrain.Eval.Scoring

  @impl true
  def score(output, target, _opts) do
    if String.contains?(output, target), do: 1.0, else: 0.0
  end

  @impl true
  def name, do: "contains"
end
