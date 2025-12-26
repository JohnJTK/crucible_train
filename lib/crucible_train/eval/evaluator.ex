defmodule CrucibleTrain.Eval.Evaluator do
  @moduledoc """
  Behaviour for evaluation routines.
  """

  @callback evaluate(struct(), term()) :: {:ok, map()} | {:error, term()}
end
