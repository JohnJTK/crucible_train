defmodule CrucibleTrain.ModelInfo do
  @moduledoc """
  Behaviour for model introspection.
  """

  @type model_config :: %{
          optional(:model_name) => String.t(),
          optional(:vocab_size) => pos_integer(),
          optional(:hidden_size) => pos_integer(),
          optional(:num_layers) => pos_integer(),
          optional(:num_heads) => pos_integer(),
          optional(:max_seq_length) => pos_integer(),
          optional(:architecture) => String.t()
        }

  @callback get_config(term()) :: {:ok, model_config()} | {:error, term()}
  @callback count_parameters(term()) :: {:ok, pos_integer()} | {:error, term()}
  @callback get_special_tokens(term()) :: {:ok, map()} | {:error, term()}

  @optional_callbacks [count_parameters: 1, get_special_tokens: 1]
end
