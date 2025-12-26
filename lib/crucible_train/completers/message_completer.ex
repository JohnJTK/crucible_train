defmodule CrucibleTrain.Completers.MessageCompleter do
  @moduledoc """
  Behaviour for message-based completers.
  """

  alias CrucibleTrain.Renderers.Types.Message

  @type t :: struct()

  @callback complete(struct(), [Message.t()]) :: {:ok, Message.t()} | {:error, term()}

  @doc """
  Dispatches completion to the completer implementation.
  """
  @spec complete(t(), [Message.t()]) :: {:ok, Message.t()} | {:error, term()}
  def complete(%module{} = completer, messages) when is_list(messages) do
    module.complete(completer, messages)
  end
end
