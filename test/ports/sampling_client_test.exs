defmodule CrucibleTrain.Ports.SamplingClientTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Ports
  alias CrucibleTrain.Ports.SamplingClient

  defmodule AdapterStub do
    def start_session(_opts, config), do: {:ok, {:session, config}}

    def sample(_opts, session, model_input, params, opts),
      do: {:ok, {:sample, session, model_input, params, opts}}

    def sample_stream(_opts, session, model_input, params, opts),
      do: {:ok, {:stream, session, model_input, params, opts}}

    def compute_logprobs(_opts, session, model_input, opts),
      do: {:ok, {:logprobs, session, model_input, opts}}

    def await(_opts, future), do: {:ok, future}
    def close_session(_opts, _session), do: :ok
  end

  test "routes sample through adapter" do
    ports = Ports.new(ports: %{sampling_client: AdapterStub})
    session = {:session, %{model: "stub"}}

    assert {:ok, {:sample, ^session, :input, %{max_tokens: 3}, []}} =
             SamplingClient.sample(ports, session, :input, %{max_tokens: 3})
  end
end
