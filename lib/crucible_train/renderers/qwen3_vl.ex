defmodule CrucibleTrain.Renderers.Qwen3VL do
  @moduledoc """
  Public wrapper for the Qwen3-VL renderer implementation.
  """

  @behaviour CrucibleTrain.Renderers.Renderer

  alias CrucibleTrain.Renderers.Implementations.Qwen3VL, as: Impl

  defdelegate init(opts), to: Impl
  defdelegate render_message(idx, message, is_last, state), to: Impl
  defdelegate bos_tokens(state), to: Impl
  defdelegate stop_sequences(state), to: Impl
  defdelegate parse_response(tokens, state), to: Impl
end

defmodule CrucibleTrain.Renderers.Qwen3VLInstruct do
  @moduledoc """
  Public wrapper for the Qwen3-VL instruct renderer implementation.
  """

  @behaviour CrucibleTrain.Renderers.Renderer

  alias CrucibleTrain.Renderers.Implementations.Qwen3VLInstruct, as: Impl

  defdelegate init(opts), to: Impl
  defdelegate render_message(idx, message, is_last, state), to: Impl
  defdelegate bos_tokens(state), to: Impl
  defdelegate stop_sequences(state), to: Impl
  defdelegate parse_response(tokens, state), to: Impl
end
