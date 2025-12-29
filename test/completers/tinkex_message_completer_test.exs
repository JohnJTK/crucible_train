defmodule CrucibleTrain.Completers.TinkexMessageCompleterTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Completers.TinkexMessageCompleter
  alias CrucibleTrain.Renderers.{Llama3, Types}
  alias CrucibleTrain.Test.SpecialTokenizer

  defmodule SamplingClientStub do
    defstruct [:response]

    def new(response), do: %__MODULE__{response: response}

    def sample(%__MODULE__{response: response}, _prompt, _params, _opts \\ []) do
      {:ok, Task.async(fn -> {:ok, response} end)}
    end
  end

  test "complete returns assistant message content" do
    {:ok, renderer_state} = Llama3.init(tokenizer: SpecialTokenizer)

    response = %{
      sequences: [
        %{
          tokens: SpecialTokenizer.encode("Hello<|eot_id|>"),
          logprobs: [-0.1]
        }
      ]
    }

    client = SamplingClientStub.new(response)

    completer =
      TinkexMessageCompleter.new(
        sampling_client: client,
        renderer_module: Llama3,
        renderer_state: renderer_state,
        max_tokens: 8
      )

    messages = [Types.message("user", "Hi")]

    assert {:ok, message} = TinkexMessageCompleter.complete(completer, messages)
    assert message.role == "assistant"
    assert message.content == "Hello"
  end
end
