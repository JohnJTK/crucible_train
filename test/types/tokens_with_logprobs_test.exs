defmodule CrucibleTrain.Types.TokensWithLogprobsTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Types.TokensWithLogprobs

  test "logprobs!/1 returns logprobs" do
    result = %TokensWithLogprobs{tokens: [1], maybe_logprobs: [-0.1]}
    assert TokensWithLogprobs.logprobs!(result) == [-0.1]
  end

  test "logprobs!/1 raises when missing" do
    result = %TokensWithLogprobs{tokens: [1], maybe_logprobs: nil}

    assert_raise ArgumentError, ~r/Logprobs are not available/, fn ->
      TokensWithLogprobs.logprobs!(result)
    end
  end
end
