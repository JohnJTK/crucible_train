defmodule CrucibleTrain.Renderers.Qwen3 do
  @moduledoc """
  Public wrapper for the Qwen3 renderer implementation.
  """

  @behaviour CrucibleTrain.Renderers.Renderer

  alias CrucibleTrain.Renderers.Implementations.Qwen3, as: Impl

  defdelegate init(opts), to: Impl
  defdelegate render_message(idx, message, is_last, state), to: Impl
  defdelegate bos_tokens(state), to: Impl
  defdelegate stop_sequences(state), to: Impl
  defdelegate parse_response(tokens, state), to: Impl
end

defmodule CrucibleTrain.Renderers.Qwen3DisableThinking do
  @moduledoc """
  Public wrapper for the Qwen3 disable-thinking renderer.
  """

  @behaviour CrucibleTrain.Renderers.Renderer

  alias CrucibleTrain.Renderers.Implementations.Qwen3DisableThinking, as: Impl

  defdelegate init(opts), to: Impl
  defdelegate render_message(idx, message, is_last, state), to: Impl
  defdelegate bos_tokens(state), to: Impl
  defdelegate stop_sequences(state), to: Impl
  defdelegate parse_response(tokens, state), to: Impl
  defdelegate build_generation_prompt(messages, role, prefill, state), to: Impl
end

defmodule CrucibleTrain.Renderers.Qwen3Instruct do
  @moduledoc """
  Public wrapper for the Qwen3 instruct renderer.
  """

  @behaviour CrucibleTrain.Renderers.Renderer

  alias CrucibleTrain.Renderers.Implementations.Qwen3Instruct, as: Impl

  defdelegate init(opts), to: Impl
  defdelegate render_message(idx, message, is_last, state), to: Impl
  defdelegate bos_tokens(state), to: Impl
  defdelegate stop_sequences(state), to: Impl
  defdelegate parse_response(tokens, state), to: Impl
end
