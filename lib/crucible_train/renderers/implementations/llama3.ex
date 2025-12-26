defmodule CrucibleTrain.Renderers.Implementations.Llama3 do
  @moduledoc """
  Llama 3 family renderer.
  """

  @behaviour CrucibleTrain.Renderers.Renderer

  alias CrucibleTrain.Renderers.{Helpers, Types}
  alias CrucibleTrain.Types.EncodedTextChunk

  @type state :: %{tokenizer: module() | map()}

  @bos_str "<|begin_of_text|>"
  @start_header "<|start_header_id|>"
  @end_header "<|end_header_id|>"
  @eot_id "<|eot_id|>"

  @impl true
  @spec init(keyword()) :: {:ok, state()}
  def init(opts) do
    tokenizer = Keyword.fetch!(opts, :tokenizer)
    {:ok, %{tokenizer: tokenizer}}
  end

  @impl true
  @spec bos_tokens(state()) :: [non_neg_integer()]
  def bos_tokens(%{tokenizer: tokenizer}) do
    encode(tokenizer, @bos_str, add_special_tokens: false)
  end

  @impl true
  @spec stop_sequences(state()) :: [non_neg_integer()]
  def stop_sequences(%{tokenizer: tokenizer}) do
    tokens = encode(tokenizer, @eot_id, add_special_tokens: false)

    case tokens do
      [token] ->
        [token]

      _ ->
        raise ArgumentError, "Expected single token for <|eot_id|>, got #{length(tokens)}"
    end
  end

  @impl true
  @spec render_message(non_neg_integer(), Types.Message.t(), boolean(), state()) ::
          {Types.RenderedMessage.t(), state()}
  def render_message(_idx, message, _is_last, %{tokenizer: tokenizer} = state) do
    role = message.role

    if message.thinking != nil do
      raise ArgumentError, "CoT tokens not supported in Llama3"
    end

    unless is_binary(message.content) do
      raise ArgumentError, "Llama3Renderer only supports message with string content"
    end

    content = Types.ensure_text(message.content)

    prefix_str = "#{@start_header}#{role}#{@end_header}\n\n"
    prefix_tokens = encode(tokenizer, prefix_str, add_special_tokens: false)

    content_str = "#{content}#{@eot_id}"
    content_tokens = encode(tokenizer, content_str, add_special_tokens: false)

    rendered = %Types.RenderedMessage{
      prefix: %EncodedTextChunk{tokens: prefix_tokens},
      content: [%EncodedTextChunk{tokens: content_tokens}],
      suffix: nil
    }

    {rendered, state}
  end

  @impl true
  @spec parse_response([non_neg_integer()], state()) :: {Types.Message.t(), boolean()}
  def parse_response(tokens, %{tokenizer: tokenizer} = state) do
    [stop_token] = stop_sequences(state)
    Helpers.parse_response_for_stop_token(tokens, tokenizer, stop_token)
  end

  defp encode(tokenizer, text, opts) when is_atom(tokenizer) do
    tokenizer.encode(text, opts)
  end

  defp encode(%{encode: encode_fn}, text, opts) when is_function(encode_fn, 2) do
    encode_fn.(text, opts)
  end
end
