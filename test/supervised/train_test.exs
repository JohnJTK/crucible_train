defmodule CrucibleTrain.Supervised.TrainTest do
  use ExUnit.Case, async: true

  alias CrucibleTrain.Supervised.{Config, DatasetFromList, Train}
  alias CrucibleTrain.Types.{Datum, ModelInput, TensorData}

  defmodule TrainingClientStub do
    defstruct []

    def forward_backward(_client, batch) do
      {:ok, Task.async(fn -> {:ok, %{metrics: %{"loss" => length(batch)}}} end)}
    end

    def optim_step(_client, _params) do
      {:ok, Task.async(fn -> {:ok, %{}} end)}
    end
  end

  defp datum_for(id) do
    model_input = ModelInput.from_ints([id, id + 1])

    Datum.new(model_input, %{
      "weights" => TensorData.from_list([1.0], :float32),
      "target_tokens" => TensorData.from_list([id + 1], :int64)
    })
  end

  test "train runs through dataset" do
    data = [datum_for(1), datum_for(3)]
    dataset = DatasetFromList.new(data, 1)

    config = %Config{
      training_client: %TrainingClientStub{},
      train_dataset: dataset,
      num_epochs: 1,
      learning_rate: 1.0e-4
    }

    assert {:ok, result} = Train.main(config)
    assert result.total_steps == 2
    assert length(result.metrics) == 2
  end
end
