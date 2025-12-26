defmodule CrucibleTrain.Renderers.Llama3 do
  @moduledoc """
  Public wrapper for the Llama3 renderer implementation.
  """

  @behaviour CrucibleTrain.Renderers.Renderer

  alias CrucibleTrain.Renderers.Implementations.Llama3, as: Impl

  defdelegate init(opts), to: Impl
  defdelegate render_message(idx, message, is_last, state), to: Impl
  defdelegate bos_tokens(state), to: Impl
  defdelegate stop_sequences(state), to: Impl
  defdelegate parse_response(tokens, state), to: Impl
end
