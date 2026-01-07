defmodule CrucibleTrain.Adapters.Noop.TrainingClientTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Adapters.Noop.TrainingClient
  alias CrucibleTrain.Ports.Error

  test "forward_backward/4 returns a ports error" do
    assert {:error, %Error{port: :training_client, adapter: TrainingClient}} =
             TrainingClient.forward_backward([], :session, [], loss_fn: :cross_entropy)
  end

  test "forward_backward_custom/5 returns a ports error" do
    loss_fn = fn _data, _logprobs -> {:loss, %{}} end

    assert {:error, %Error{port: :training_client, adapter: TrainingClient}} =
             TrainingClient.forward_backward_custom([], :session, [], loss_fn, [])
  end
end
