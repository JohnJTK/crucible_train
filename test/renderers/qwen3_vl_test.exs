defmodule CrucibleTrain.Renderers.Qwen3VLTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Renderers.{Qwen3VL, Qwen3VLInstruct, Types}
  alias CrucibleTrain.Test.SpecialTokenizer
  alias CrucibleTrain.Types.{EncodedTextChunk, ImageChunk}

  defmodule MockImageProcessor do
    def expected_tokens(_bytes), do: 6
  end

  setup do
    image_bytes = <<0, 1, 2, 3>>
    {:ok, state} = Qwen3VL.init(tokenizer: SpecialTokenizer, image_processor: MockImageProcessor)

    %{state: state, image_bytes: image_bytes}
  end

  test "render_message wraps image parts with vision markers", %{state: state, image_bytes: bytes} do
    message = Types.message("user", [Types.image_part(bytes)])

    {rendered, _state} = Qwen3VL.render_message(0, message, false, state)

    assert [
             %EncodedTextChunk{} = vision_start,
             %ImageChunk{} = image_chunk,
             %EncodedTextChunk{} = vision_end,
             %EncodedTextChunk{} = im_end
           ] = rendered.content

    assert SpecialTokenizer.decode(vision_start.tokens) == "<|vision_start|>"
    assert SpecialTokenizer.decode(vision_end.tokens) == "<|vision_end|>"
    assert SpecialTokenizer.decode(im_end.tokens) == "<|im_end|>"
    assert image_chunk.format == "raw"
    assert image_chunk.expected_tokens == 6
  end

  test "assistant without think adds think prefix", %{state: state} do
    message = Types.message("assistant", [Types.text_part("Hello")])

    {rendered, _state} = Qwen3VL.render_message(0, message, false, state)

    prefix_text = SpecialTokenizer.decode(rendered.prefix.tokens)
    assert String.contains?(prefix_text, "<think>\n")
  end

  test "instruct renderer does not add think prefix", %{state: state} do
    message = Types.message("assistant", [Types.text_part("Hello")])

    {rendered, _state} = Qwen3VLInstruct.render_message(0, message, false, state)

    prefix_text = SpecialTokenizer.decode(rendered.prefix.tokens)
    refute String.contains?(prefix_text, "<think>\n")
  end
end
