defmodule CrucibleTrain.Completers.TokenCompleter do
  @moduledoc """
  Behaviour for token-based completers.
  """

  alias CrucibleTrain.Types.{ModelInput, TokensWithLogprobs}

  @type t :: struct()

  @type stop_condition :: [String.t()] | [integer()]

  @callback complete(struct(), ModelInput.t(), stop_condition()) ::
              {:ok, TokensWithLogprobs.t()} | {:error, term()}

  @doc """
  Dispatches completion to the completer implementation.
  """
  @spec complete(t(), ModelInput.t(), stop_condition()) ::
          {:ok, TokensWithLogprobs.t()} | {:error, term()}
  def complete(%module{} = completer, %ModelInput{} = model_input, stop_condition) do
    module.complete(completer, model_input, stop_condition)
  end
end
