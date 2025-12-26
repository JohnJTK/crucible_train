defmodule CrucibleTrain.Renderers.KimiK2 do
  @moduledoc """
  Public wrapper for the Kimi K2 renderer implementation.
  """

  @behaviour CrucibleTrain.Renderers.Renderer

  alias CrucibleTrain.Renderers.Implementations.KimiK2, as: Impl

  defdelegate init(opts), to: Impl
  defdelegate render_message(idx, message, is_last, state), to: Impl
  defdelegate bos_tokens(state), to: Impl
  defdelegate stop_sequences(state), to: Impl
  defdelegate parse_response(tokens, state), to: Impl
  defdelegate build_generation_prompt(messages, role, prefill, state), to: Impl
  defdelegate build_supervised_example(messages, train_on_what, state), to: Impl
end
