defmodule CrucibleTrain.Eval.Scoring do
  @moduledoc """
  Behaviour for scoring functions.
  """

  alias CrucibleTrain.Eval.Scorers

  @callback score(output :: String.t(), target :: String.t(), opts :: keyword()) :: float()
  @callback name() :: String.t()

  @doc """
  Score using the specified method.
  """
  @spec score(atom() | module(), String.t(), String.t(), keyword()) :: float()
  def score(method, output, target, opts \\ []) do
    module = resolve(method)
    module.score(output, target, opts)
  end

  defp resolve(:exact_match), do: Scorers.ExactMatch
  defp resolve(:contains), do: Scorers.Contains
  defp resolve(:semantic_similarity), do: Scorers.SemanticSimilarity

  defp resolve(module) when is_atom(module) do
    if Code.ensure_loaded?(module) and function_exported?(module, :score, 3) do
      module
    else
      raise ArgumentError, "Unknown scoring method: #{inspect(module)}"
    end
  end

  defp resolve(other) do
    raise ArgumentError, "Unknown scoring method: #{inspect(other)}"
  end
end
