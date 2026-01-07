defmodule CrucibleTrain.Completers.PortsTokenCompleterTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Completers.PortsTokenCompleter
  alias CrucibleTrain.Ports
  alias CrucibleTrain.Types.{ModelInput, TokensWithLogprobs}

  defmodule SamplingAdapterStub do
    def start_session(_opts, config), do: {:ok, {:session, config}}

    def sample(_opts, _session, _model_input, _params, _opts_kw) do
      response = %{sequences: [%{tokens: [1], logprobs: [-1.0]}]}
      {:ok, Task.async(fn -> {:ok, response} end)}
    end

    def sample_stream(_opts, _session, _model_input, _params, _opts_kw), do: {:ok, []}

    def compute_logprobs(_opts, _session, _model_input, _opts_kw),
      do: {:ok, Task.async(fn -> {:ok, []} end)}

    def await(_opts, %Task{} = task), do: Task.await(task, :infinity)
    def await(_opts, other), do: {:ok, other}
    def close_session(_opts, _session), do: :ok
  end

  test "complete returns tokens with logprobs" do
    ports = Ports.new(ports: %{sampling_client: SamplingAdapterStub})
    session = {:session, %{model: "stub"}}

    completer =
      PortsTokenCompleter.new(
        ports: ports,
        session: session,
        max_tokens: 1,
        temperature: 1.0
      )

    model_input = ModelInput.from_ints([1])

    assert {:ok, %TokensWithLogprobs{tokens: [1], maybe_logprobs: [-1.0]}} =
             PortsTokenCompleter.complete(completer, model_input, [])
  end
end
