defmodule CrucibleTrain.Renderers.RoleColon do
  @moduledoc """
  Public wrapper for the role-colon renderer implementation.
  """

  @behaviour CrucibleTrain.Renderers.Renderer

  alias CrucibleTrain.Renderers.Implementations.RoleColon, as: Impl

  defdelegate init(opts), to: Impl
  defdelegate render_message(idx, message, is_last, state), to: Impl
  defdelegate bos_tokens(state), to: Impl
  defdelegate stop_sequences(state), to: Impl
  defdelegate parse_response(tokens, state), to: Impl
end
