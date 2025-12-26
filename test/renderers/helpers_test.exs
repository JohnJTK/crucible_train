defmodule CrucibleTrain.Renderers.HelpersTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Renderers.Helpers
  alias CrucibleTrain.Test.MockTokenizer
  alias CrucibleTrain.Types.TensorData

  test "tokens_weights_from_strings_weights aligns weights with tokens" do
    strings_weights = [
      {"Hi", 0.0},
      {"Yo", 1.0}
    ]

    {tokens, weights} =
      Helpers.tokens_weights_from_strings_weights(strings_weights, MockTokenizer)

    assert TensorData.to_list(tokens) == MockTokenizer.encode("HiYo")
    assert TensorData.to_list(weights) == [0.0, 0.0, 1.0, 1.0]
  end
end
