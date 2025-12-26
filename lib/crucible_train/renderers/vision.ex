defmodule CrucibleTrain.Renderers.Vision do
  @moduledoc """
  Minimal image helpers for vision-capable renderers.

  This module intentionally avoids external image dependencies. It expects
  callers to supply raw image bytes and an image_processor that can provide
  `expected_tokens` for those bytes.
  """

  alias CrucibleTrain.Types.ImageChunk

  @type image_processor :: module() | map()

  @spec image_to_chunk(ImageChunk.t() | binary(), image_processor()) :: ImageChunk.t()
  def image_to_chunk(%ImageChunk{} = chunk, _image_processor), do: chunk

  def image_to_chunk(%{data: data, format: format, expected_tokens: expected_tokens}, _processor)
      when is_binary(data) and is_binary(format) and is_integer(expected_tokens) do
    ImageChunk.new(data, format, expected_tokens)
  end

  def image_to_chunk(image_bytes, image_processor) when is_binary(image_bytes) do
    expected_tokens = expected_tokens_from_processor(image_processor, image_bytes)
    ImageChunk.new(image_bytes, "raw", expected_tokens)
  end

  def image_to_chunk(other, _image_processor) do
    raise ArgumentError,
          "Unsupported image input. Provide raw image bytes or an ImageChunk: #{inspect(other)}"
  end

  defp expected_tokens_from_processor(image_processor, image_bytes)
       when is_atom(image_processor) do
    if function_exported?(image_processor, :expected_tokens, 1) do
      image_processor.expected_tokens(image_bytes)
    else
      raise ArgumentError, "Image processor missing expected_tokens/1"
    end
  end

  defp expected_tokens_from_processor(image_processor, image_bytes)
       when is_map(image_processor) do
    fun =
      Map.get(image_processor, :expected_tokens) || Map.get(image_processor, "expected_tokens")

    cond do
      is_function(fun, 1) ->
        fun.(image_bytes)

      is_integer(fun) ->
        fun

      true ->
        raise ArgumentError, "Image processor missing expected_tokens"
    end
  end

  defp expected_tokens_from_processor(other, _image_bytes) do
    raise ArgumentError, "Invalid image processor: #{inspect(other)}"
  end
end
