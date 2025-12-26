defmodule CrucibleTrain.Completers.MockCompleterTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Completers.MockCompleter
  alias CrucibleTrain.Renderers.Types
  alias CrucibleTrain.Types.{ModelInput, TokensWithLogprobs}

  test "returns configured token result" do
    result = %TokensWithLogprobs{tokens: [1, 2], maybe_logprobs: [0.1, 0.2]}
    completer = MockCompleter.new(token_result: result)

    model_input = ModelInput.from_ints([1])

    assert {:ok, ^result} = MockCompleter.complete(completer, model_input, ["<|stop|>"])
  end

  test "returns configured message result" do
    message = Types.message("assistant", "ok")
    completer = MockCompleter.new(message_result: message)

    assert {:ok, ^message} = MockCompleter.complete(completer, [Types.message("user", "hi")])
  end

  test "returns error when no result configured" do
    completer = MockCompleter.new()
    model_input = ModelInput.from_ints([1])

    assert {:error, :no_token_result} = MockCompleter.complete(completer, model_input, [])
    assert {:error, :no_message_result} = MockCompleter.complete(completer, [])
  end
end
