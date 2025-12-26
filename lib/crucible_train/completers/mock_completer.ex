defmodule CrucibleTrain.Completers.MockCompleter do
  @moduledoc """
  Deterministic completer for tests.
  """

  @behaviour CrucibleTrain.Completers.TokenCompleter
  @behaviour CrucibleTrain.Completers.MessageCompleter

  alias CrucibleTrain.Renderers.Types.Message
  alias CrucibleTrain.Types.{ModelInput, TokensWithLogprobs}

  @type t :: %__MODULE__{
          token_result: TokensWithLogprobs.t() | nil,
          message_result: Message.t() | nil,
          token_fn:
            (t(), ModelInput.t(), CrucibleTrain.Completers.TokenCompleter.stop_condition() ->
               {:ok, TokensWithLogprobs.t()} | {:error, term()})
            | nil,
          message_fn: (t(), [Message.t()] -> {:ok, Message.t()} | {:error, term()}) | nil
        }

  defstruct [:token_result, :message_result, :token_fn, :message_fn]

  @doc """
  Builds a new mock completer.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      token_result: Keyword.get(opts, :token_result),
      message_result: Keyword.get(opts, :message_result),
      token_fn: Keyword.get(opts, :token_fn),
      message_fn: Keyword.get(opts, :message_fn)
    }
  end

  @impl true
  def complete(%__MODULE__{} = mock, %ModelInput{} = model_input, stop_condition) do
    cond do
      is_function(mock.token_fn, 3) ->
        mock.token_fn.(mock, model_input, stop_condition)

      is_function(mock.token_fn, 2) ->
        mock.token_fn.(model_input, stop_condition)

      true ->
        case mock.token_result do
          %TokensWithLogprobs{} = result -> {:ok, result}
          _ -> {:error, :no_token_result}
        end
    end
  end

  @impl true
  def complete(%__MODULE__{} = mock, messages) when is_list(messages) do
    cond do
      is_function(mock.message_fn, 2) ->
        mock.message_fn.(mock, messages)

      is_function(mock.message_fn, 1) ->
        mock.message_fn.(messages)

      true ->
        case mock.message_result do
          %Message{} = result -> {:ok, result}
          _ -> {:error, :no_message_result}
        end
    end
  end
end
