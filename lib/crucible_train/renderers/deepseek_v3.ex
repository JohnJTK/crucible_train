defmodule CrucibleTrain.Renderers.DeepSeekV3 do
  @moduledoc """
  Public wrapper for the DeepSeek V3 renderer implementation.
  """

  @behaviour CrucibleTrain.Renderers.Renderer

  alias CrucibleTrain.Renderers.Implementations.DeepSeekV3, as: Impl

  defdelegate init(opts), to: Impl
  defdelegate render_message(idx, message, is_last, state), to: Impl
  defdelegate bos_tokens(state), to: Impl
  defdelegate stop_sequences(state), to: Impl
  defdelegate parse_response(tokens, state), to: Impl
end

defmodule CrucibleTrain.Renderers.DeepSeekV3DisableThinking do
  @moduledoc """
  Public wrapper for the DeepSeek V3 disable-thinking renderer.
  """

  @behaviour CrucibleTrain.Renderers.Renderer

  alias CrucibleTrain.Renderers.Implementations.DeepSeekV3DisableThinking, as: Impl

  defdelegate init(opts), to: Impl
  defdelegate render_message(idx, message, is_last, state), to: Impl
  defdelegate bos_tokens(state), to: Impl
  defdelegate stop_sequences(state), to: Impl
  defdelegate parse_response(tokens, state), to: Impl
  defdelegate build_generation_prompt(messages, role, prefill, state), to: Impl
end
