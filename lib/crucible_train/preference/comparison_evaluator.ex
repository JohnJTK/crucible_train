defmodule CrucibleTrain.Preference.ComparisonEvaluator do
  @moduledoc """
  Simple evaluator for labeled comparisons.
  """

  alias CrucibleTrain.Preference.LabeledComparison

  @type predict_fn :: (LabeledComparison.t() -> String.t())

  @doc """
  Computes accuracy over labeled comparisons using a prediction function.
  """
  @spec evaluate([LabeledComparison.t()], predict_fn()) :: map()
  def evaluate(labeled, predict_fn) when is_list(labeled) and is_function(predict_fn, 1) do
    total = length(labeled)

    correct =
      Enum.count(labeled, fn comparison ->
        predict_fn.(comparison) == comparison.label
      end)

    accuracy = if total == 0, do: 0.0, else: correct / total

    %{accuracy: accuracy, total: total, correct: correct}
  end
end
