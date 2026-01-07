defmodule CrucibleTrain.Adapters.Noop.SamplingClientTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Adapters.Noop.SamplingClient
  alias CrucibleTrain.Ports.Error

  test "start_session returns a ports error" do
    assert {:error, %Error{port: :sampling_client, adapter: SamplingClient}} =
             SamplingClient.start_session([], %{})
  end

  test "sample returns a ports error" do
    assert {:error, %Error{port: :sampling_client, adapter: SamplingClient}} =
             SamplingClient.sample([], :session, :input, %{}, [])
  end
end
