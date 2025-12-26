defmodule CrucibleTrain.Types.TokensWithLogprobs do
  @moduledoc """
  Token completion result with optional logprobs.
  """

  @type t :: %__MODULE__{
          tokens: [integer()],
          maybe_logprobs: [float()] | nil
        }

  defstruct [:tokens, :maybe_logprobs]

  @doc """
  Returns logprobs or raises when they are not available.
  """
  @spec logprobs!(t()) :: [float()]
  def logprobs!(%__MODULE__{maybe_logprobs: nil}) do
    raise ArgumentError, "Logprobs are not available"
  end

  def logprobs!(%__MODULE__{maybe_logprobs: logprobs}), do: logprobs
end
